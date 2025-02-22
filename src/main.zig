const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const validation = @import("./validation.zig");

const global = @import("./global.zig");
const State = @import("./state.zig").State;

const ws = @import("./ws.zig");

fn on_request(r: zap.Request) void {
    r.setStatus(.not_found);
    r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
}

fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    var GlobalContextManager = global.get_context_manager();

    const log = std.log.scoped(.websocket_upgrade);

    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        log.warn("received illegal protocol: {s}", .{target_protocol});
        return validation.deny_request(r);
    }

    if (GlobalState.is_ip_blocked(r)) {
        log.warn("received illegal request: IP is blocked", .{});
        return validation.deny_request(r);
    }

    const username = r.getParamSlice("username") orelse {
        log.warn("received illegal request: no username provided", .{});
        return validation.deny_request(r);
    };

    if (!validation.is_valid_user(username)) {
        log.warn("received illegal request: username '{s}' is invalid", .{username});
        return validation.deny_request(r);
    }

    const ownedUsername = GlobalContextManager.allocator.dupe(u8, username) catch |err| {
        std.log.err("failed to clone the username '{s}' into owned memory: {}", .{ username, err });
        return;
    };

    var context = GlobalContextManager.newContext(ownedUsername) catch |err| {
        log.err("error creating context: {any}", .{err});
        return validation.deny_request(r);
    };

    WebSocketHandler.upgrade(r.h, &context.settings) catch |err| {
        log.err("error in WebSocketHandler.upgrade(): {any}", .{err});
        return validation.deny_request(r);
    };

    log.debug("successful upgrade for user: {s}", .{ownedUsername});
}

var GlobalState: State = undefined;

const WebSocketHandler = ws.WebSocketHandler;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.debug("GPA detected a memory leak!", .{});
    }

    GlobalState = State.init(allocator);
    defer GlobalState.deinit();

    var GlobalContextManager = global.init_context_manager(allocator);
    defer GlobalContextManager.deinit();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    var port: usize = 3000;
    var frontendDirectory: []const u8 = "public";

    while (args_it.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--port=")) {
            if (std.fmt.parseUnsigned(usize, arg[7..], 0)) |the_port| {
                port = the_port;
                std.log.debug("port, huh I've heard that somewhere.... [EASTER EGG, DO NOT DEBUG]", .{});
            } else |_| {
                std.log.warn("Invalid port number. Using default port {}\n", .{port});
            }
        }

        if (std.mem.startsWith(u8, arg, "--frontend=")) {
            frontendDirectory = arg[11..];
        }
    }

    var listener = zap.HttpListener.init(.{
        .port = port,
        .on_request = on_request,
        .on_upgrade = on_upgrade,
        .max_clients = 1024,
        .max_body_size = 1 * 1024,
        .ws_timeout = 60, // disconnects, if no response in 60s
        .public_folder = frontendDirectory,
        .log = builtin.mode == .Debug,
    });
    try listener.listen();

    std.log.info("HTTP server listening on http://localhost:3000", .{});
    std.log.info("WebSocket server listening on ws://localhost:3000", .{});
    std.log.info("Terminate with CTRL+C", .{});

    zap.start(.{
        .threads = @intCast(try std.Thread.getCpuCount()),
        .workers = 4,
    });
}
