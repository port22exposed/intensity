const std = @import("std");

pub const State = struct {
    allocator: std.mem.Allocator,
    blocked_ips: std.ArrayList([]u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .blocked_ips = std.ArrayList([]u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.blocked_ips.deinit();
    }
};
