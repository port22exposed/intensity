const std = @import("std");

pub fn contains(list: *const std.ArrayList([]const u8), target: []const u8) bool {
    for (list.items) |item| {
        if (std.mem.eql(u8, item, target)) {
            return true;
        }
    }
    return false;
}
