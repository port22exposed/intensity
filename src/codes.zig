const std = @import("std");

pub const JoinCode = struct {
    allocator: std.mem.Allocator,
    code: []const u8,
    timestamp: i64,
    username: []const u8,
    randomComponent: []const u8,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, code: []const u8) !Self {
        const first_sep_index = std.mem.indexOf(u8, code, "|") orelse {
            return error.InvalidCode;
        };
        const id = code[0..first_sep_index];

        const rest = code[first_sep_index + 1 ..];
        const second_sep_index = std.mem.indexOf(u8, rest, "|") orelse {
            return error.InvalidCode;
        };

        const username = rest[0..second_sep_index];
        const random_component = rest[second_sep_index + 1 ..];

        return Self{ .allocator = allocator, .code = code, .timestamp = try std.fmt.parseInt(i64, id, 10), .username = username, .randomComponent = random_component };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.code);
    }
};

test "JoinCode tests" {
    const parsed = try JoinCode.parse(std.testing.allocator, "1234|username|randomcodethatcancontain|the|separator");
    try std.testing.expectEqual(1234, parsed.timestamp);
    try std.testing.expectEqualStrings("username", parsed.username);
    try std.testing.expectEqualStrings("randomcodethatcancontain|the|separator", parsed.randomComponent);
}
