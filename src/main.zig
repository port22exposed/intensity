const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const validation = @import("./validation.zig");

const State = @import("./state.zig").State;

fn on_request(r: zap.Request) void {
    r.setStatus(.not_found);
    r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
}

fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        validation.deny_request(r);
        return;
    }

    if (GlobalState.is_ip_blocked(r)) {
        std.log.warn("received illegal websocket upgrade request: IP is blocked", .{});
        validation.deny_request(r);
        return;
    }

    const username: ?[]const u8 = r.getParamSlice("username");

    if (username == null) {
        std.log.warn("received illegal websocket upgrade request: no username provided", .{});
        GlobalState.block_ip(r); // GET OUT!
        validation.deny_request(r);
        return;
    }
}

var GlobalState: State = undefined;

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

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .on_upgrade = on_upgrade,
        .max_clients = 1024,
        .max_body_size = 1 * 1024,
        .ws_timeout = 60, // disconnects, if no response in 60s
        .public_folder = "public",
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
