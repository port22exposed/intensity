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

const UpgradeError = error{ IllegalProtocol, IllegalRequest, AllocationException, ContextCreationException, WebSocketHandlerUpgradeFail };

fn internal_upgrade(r: zap.Request, target_protocol: []const u8) UpgradeError!void {
    const GlobalContextManager = global.get_context_manager();
    defer GlobalContextManager.mutex.unlock();

    const GlobalState = global.get_state();
    defer GlobalState.mutex.unlock();

    const allocator = GlobalContextManager.allocator;

    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        return error.IllegalProtocol;
    }

    const ip = validation.get_ip(r) orelse {
        return error.IllegalRequest;
    };

    if (GlobalState.is_ip_blocked(ip)) {
        return error.IllegalRequest;
    }

    const username = r.getParamSlice("username") orelse {
        return error.IllegalRequest;
    };

    if (!validation.is_valid_user(username)) {
        return error.IllegalRequest;
    }

    const ownedUsername = allocator.dupe(u8, username) catch {
        return error.AllocationException;
    };

    const ownedIp = allocator.dupe(u8, ip) catch {
        allocator.free(ownedUsername); // somehow username was allocated but the IP address wasn't
        return error.AllocationException;
    };

    var context = GlobalContextManager.newContext(ownedUsername, ownedIp) catch {
        return error.ContextCreationException;
    };

    if (GlobalContextManager.contexts.items.len <= 1) {
        context.accepted = true;
    }

    WebSocketHandler.upgrade(r.h, &context.settings) catch {
        allocator.free(ownedUsername);
        allocator.free(ownedIp);
        return error.WebSocketHandlerUpgradeFail;
    };
}

fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    const log = std.log.scoped(.websocket_upgrade);

    internal_upgrade(r, target_protocol) catch |err| {
        switch (err) {
            error.IllegalProtocol => log.warn("received illegal protocol: {s}", .{target_protocol}),
            error.IllegalRequest => log.warn("received illegal request", .{}),
            error.AllocationException => log.err("failed to allocate memory", .{}),
            error.ContextCreationException => log.err("error creating context", .{}),
            error.WebSocketHandlerUpgradeFail => log.err("error in WebSocketHandler.upgrade(): {any}", .{err}),
        }
        return validation.deny_request(r);
    };
}

const WebSocketHandler = ws.WebSocketHandler;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
        .stack_trace_frames = 32,
    }){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.debug("GPA detected a memory leak!", .{});
    }

    var GlobalContextManager = global.init_context_manager(allocator);
    defer GlobalContextManager.deinit();

    var GlobalState = global.init_state(allocator);
    defer GlobalState.deinit();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    var port: usize = 3000;
    var frontendDirectory: []const u8 = "public";
    var threads: u8 = 2;
    var workers: u8 = 1;

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

        if (std.mem.startsWith(u8, arg, "--threads=")) {
            if (std.fmt.parseUnsigned(u8, arg[10..], 0)) |the_threads| {
                threads = the_threads;
            } else |_| {
                std.log.warn("Invalid thread count (range of 1-255). Using default of {}\n", .{threads});
            }
        }

        if (std.mem.startsWith(u8, arg, "--workers=")) {
            if (std.fmt.parseUnsigned(u8, arg[10..], 0)) |the_workers| {
                workers = the_workers;
            } else |_| {
                std.log.warn("Invalid worker count (range of 1-255). Using default of {}\n", .{workers});
            }
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
        .threads = threads,
        .workers = workers,
    });
}
