const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

fn deny_request(r: zap.Request) void {
    r.setStatus(.bad_request);
    r.sendBody("400 - BAD REQUEST") catch unreachable;
}

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        deny_request(r);
        return;
    }

    const allocator = std.heap.page_allocator;

    r.parseQuery(); // this took too long to find please explode zig zap!

    var username: ?[]u8 = null;

    if (r.getParamStr(allocator, "username", false)) |maybe_username| {
        if (maybe_username) |*name| {
            defer name.deinit(); // the docs for this are weird, it may not be needed
            username = allocator.alloc(u8, name.str.len) catch unreachable;
            @memcpy(username.?, name.str);
        } else {
            deny_request(r);
            return;
        }
    } else |e| {
        std.log.err("failed to get `username` parameter string: {any}", .{e});
        deny_request(r);
        return;
    }

    std.log.info("username: {s}", .{username.?});

    // } else {
    //     deny_request(r);
    // }

    // if (username) |name| {
    //     std.log.info("username: {s}", .{name});
    // } else {
    //     deny_request(r);
    // }
}
