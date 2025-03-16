const std = @import("std");

const rand = std.crypto.random;

pub fn randomString(allocator: std.mem.Allocator, length: usize) ![]u8 {
    var result = try std.ArrayList(u8).initCapacity(allocator, length);
    errdefer result.deinit();

    for (0..16) |_| {
        const char = rand.intRangeAtMost(u8, 33, 126);
        try result.append(char);
    }

    const slice = try result.toOwnedSlice();
    return slice;
}
