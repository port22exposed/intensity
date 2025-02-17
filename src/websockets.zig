const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        r.setStatus(.bad_request);
        r.sendBody("400 - BAD REQUEST") catch unreachable;
        return;
    }
}
