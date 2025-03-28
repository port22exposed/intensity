const std = @import("std");

const utility = @import("./utility.zig");

pub const RANDOM_COMPONENT_LENGTH = 2048;
pub const MAX_USERNAME_LENGTH = 20;
pub const MAX_JOIN_CODE_LENGTH = MAX_USERNAME_LENGTH + RANDOM_COMPONENT_LENGTH + 1; // Accounts for the username and random_component length + 1 for the separator character.

pub const JoinCode = struct {
    allocator: std.mem.Allocator,
    code: []u8,
    username: []u8,
    random_component: []u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, username: []const u8) !Self {
        const code = try allocator.alloc(u8, username.len + 1 + RANDOM_COMPONENT_LENGTH);

        var index: usize = 0;

        std.mem.copyForwards(u8, code[index..][0..username.len], username);
        const username_slice = code[index..][0..username.len];
        index += username.len;

        code[index] = '|';
        index += 1;

        const random_component = try utility.randomString(allocator, RANDOM_COMPONENT_LENGTH);
        defer allocator.free(random_component);

        std.mem.copyForwards(u8, code[index..][0..RANDOM_COMPONENT_LENGTH], random_component);
        const random_component_slice = code[index..][0..RANDOM_COMPONENT_LENGTH];

        return Self{
            .allocator = allocator,
            .code = code,
            .username = username_slice,
            .random_component = random_component_slice,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.code);
    }
};

test "JoinCode tests" {
    defer _ = std.testing.allocator_instance.detectLeaks();

    const allocator = std.testing.allocator;

    const username = "meow";

    const join_code = try JoinCode.init(allocator, username);
    defer join_code.deinit();

    try std.testing.expectEqualStrings(username, join_code.username);
}
