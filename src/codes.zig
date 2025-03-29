const std = @import("std");

const utility = @import("./utility.zig");

pub const RANDOM_COMPONENT_LENGTH = 128;

pub const JoinCode = struct {
    allocator: std.mem.Allocator,
    code: []u8,
    username: []u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, username: []const u8) !Self {
        const owned_username = try allocator.dupe(u8, username);
        const code = try utility.randomString(allocator, RANDOM_COMPONENT_LENGTH);

        return Self{
            .allocator = allocator,
            .code = code,
            .username = owned_username,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.code);
    }
};
