const std = @import("std");
const zap = @import("zap");

pub fn on_request(r: zap.Request) void {
    r.setStatus(.not_found);
    r.sendBody("<html><body><h1>404 - File not found</h1></body></html>") catch return;
}
