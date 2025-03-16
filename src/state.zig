const std = @import("std");

const rand = std.crypto.random;

pub const State = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    join_codes: std.ArrayList([]u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .mutex = std.Thread.Mutex{},
            .join_codes = std.ArrayList([]u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.join_codes.items) |item| {
            self.allocator.free(item);
        }
        self.join_codes.deinit();
    }
};
