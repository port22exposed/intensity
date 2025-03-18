const std = @import("std");

pub const JoinCode = struct {
    allocator: std.mem.Allocator,
    code: []u8,
    timestamp: i64,
    random_component: []u8,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, code: []u8) !Self {
        const first_sep_index = std.mem.indexOf(u8, code, "|") orelse {
            return error.InvalidCode;
        };
        const timestamp = code[0..first_sep_index];
        const random_component = code[first_sep_index + 1 ..];

        return Self{
            .allocator = allocator,
            .code = code,
            .timestamp = try std.fmt.parseInt(i64, timestamp, 10),
            .random_component = random_component,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.code);
    }
};

test "JoinCode tests" {
    defer _ = std.testing.allocator_instance.detectLeaks();

    const timestamp: i64 = 1234;
    const random_component: []const u8 = "randomcodethatcancontain|the|separator";

    const code = try std.fmt.allocPrint(std.testing.allocator, "{d}|{s}", .{ timestamp, random_component });

    const parsed = try JoinCode.parse(std.testing.allocator, code);
    defer parsed.deinit();

    try std.testing.expectEqual(timestamp, parsed.timestamp);
    try std.testing.expectEqualStrings(random_component, parsed.random_component);
}
