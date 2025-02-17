const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

fn deny_request(r: zap.Request) void {
    r.setStatus(.bad_request);
    r.sendBody("400 - BAD REQUEST") catch unreachable;
    return;
}

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        deny_request(r);
    }

    var username: ?[]const u8 = undefined;

    if (r.query) |query| {
        var params = std.mem.splitAny(u8, query, "&");
        while (params.next()) |param| {
            var kv = std.mem.split(u8, param, "=");
            if (kv.next()) |key| {
                if (kv.next()) |value| {
                    if (std.mem.eql(u8, key, "username")) {
                        username = value;
                    }
                }
            }
        }
    } else {
        deny_request(r);
    }

    if (username) |name| {
        std.log.info("username: {s}", .{name});
    } else {
        deny_request(r);
    }
}
