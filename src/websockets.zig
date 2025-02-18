const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

fn deny_request(r: zap.Request) void {
    r.setStatus(.bad_request);
    r.sendBody("400 - BAD REQUEST") catch unreachable;
}

// Usernames must be between 3-20 characters
// Character set of A-Z, a-z, 0-9 or _ and -
fn is_valid_user(username: []const u8) bool {
    var valid = true;

    for (username) |char| {
        if (!std.ascii.isAlphanumeric(char) and char != '_' and char != '-') {
            valid = false;
        }
    }

    if (username.len < 3 or username.len > 20) {
        valid = false;
    }

    return valid;
}

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        deny_request(r);
        return;
    }

    const username: ?[]const u8 = r.getParamSlice("username");

    if (username == null) {
        std.log.warn("received websocket connection request without a username provided", .{});
        deny_request(r);
        return;
    }
}
