const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

pub fn deny_request(r: zap.Request) void {
    r.setStatus(.bad_request);
    r.sendBody("400 - BAD REQUEST") catch unreachable;
    return;
}

// Usernames must be between 3-20 characters
// Character set of A-Z, a-z, 0-9 or _ and -
pub fn is_valid_user(username: []const u8) bool {
    for (username) |char| {
        if (!std.ascii.isAlphanumeric(char) and char != '_' and char != '-') {
            return false;
        }
    }

    if (username.len <= 3 or username.len >= 20) {
        return false;
    }

    return true;
}

pub fn get_ip(r: zap.Request) ?[]const u8 {
    const ip = r.getHeader("cf-connecting-ip") orelse r.getHeader("x-forwarded-for") orelse r.getHeader("x-real-ip") orelse null;

    return ip;
}
