const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const websockets = @import("./websockets.zig");

fn on_request(r: zap.Request) void {
    r.setStatus(.not_found);
    r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
}

pub fn main() !void {
    // Required for the GPA
    websockets.init();
    defer websockets.deinit();

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .on_upgrade = websockets.on_upgrade,
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
