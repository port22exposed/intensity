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

/// Generates a random **alphanumeric** string in the form of a u8 byte array.
/// The caller must free the memory!
pub fn randomAlphanumericString(allocator: std.mem.Allocator, length: usize) ![]u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, length);
    errdefer result.deinit();

    for (0..length) |_| {
        const random_value = rand.intRangeAtMost(u8, 0, 61);

        // 0-9 (10 digits) -> '0' to '9' (ASCII 48-57)
        // 10-35 (26 letters) -> 'A' to 'Z' (ASCII 65-90)
        // 36-61 (26 letters) -> 'a' to 'z' (ASCII 97-122)
        const char = if (random_value < 10)
            '0' + random_value
        else if (random_value < 36)
            'A' + (random_value - 10)
        else
            'a' + (random_value - 36);

        try result.append(char);
    }

    const slice = try result.toOwnedSlice();
    return slice;
}
