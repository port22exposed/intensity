const std = @import("std");

const rand = std.crypto.random;

/// Generates a random string in the form of a u8 byte array.
/// The caller must free the memory!
pub fn randomString(allocator: std.mem.Allocator, length: usize) ![]u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, length);
    errdefer result.deinit();

    for (0..length) |_| {
        const char = rand.intRangeAtMost(u8, 33, 126);
        try result.append(char);
    }

    const slice = try result.toOwnedSlice();
    return slice;
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
