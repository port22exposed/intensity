const std = @import("std");

const rand = std.crypto.random;

/// Generates a random string in the form of a u8 byte array.
/// The caller must free the memory!
pub fn randomString(allocator: std.mem.Allocator, length: usize) ![]u8 {
    const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-";

    var result = try std.ArrayList(u8).initCapacity(allocator, length);

    for (0..length) |_| {
        const index = try rand.intRangeAtMost(usize, 0, charset.len - 1);
        try result.append(charset[index]);
    }

    return try result.toOwnedSlice();
}

/// Username validation
/// Usernames must be 3>=x=<20 characters in length
/// Usernames must be alphanumeric [A-Z][a-z][0-9]
pub fn validateUsername(username: []const u8) !void {
    if (username.len < 3 or username.len > 20) {
        return error.InvalidLength;
    }

    for (username) |character| {
        if (!std.ascii.isAlphanumeric(character)) {
            return error.InvalidCharacters;
        }
    }
}
