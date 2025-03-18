const std = @import("std");
const zap = @import("zap");

const internal_request = @import("./internal.zig").internal_request;

pub fn on_request(r: zap.Request) void {
    internal_request(r) catch |e| switch (e) {
        else => {
            r.setStatus(.not_found);
            r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
        },
    };
}
