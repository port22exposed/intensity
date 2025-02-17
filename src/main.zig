const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

fn on_request(r: zap.Request) void {
    r.sendBody("<html><body><h1>error 404: not found</h1></body></html>") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
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
