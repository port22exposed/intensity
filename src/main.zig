const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const websockets = @import("./websockets.zig");

fn on_request(r: zap.Request) void {
    r.setStatus(.not_found);
    r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .on_upgrade = websockets.on_upgrade,
        .max_clients = 1000,
        .max_body_size = 1 * 1024,
        .ws_timeout = 60, // disconnects, if no response in 60s
        .public_folder = "public",
        .log = builtin.mode == .Debug,
    });
    try listener.listen();

    std.debug.print("Listening on http://localhost:3000\n", .{});

    zap.start(.{
        .threads = @intCast(try std.Thread.getCpuCount()),
        .workers = 4,
    });
}
