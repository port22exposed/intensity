const std = @import("std");

const rand = std.crypto.random;

const JoinCode = @import("./codes.zig").JoinCode;

pub const State = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    join_codes: std.ArrayList(JoinCode),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .mutex = std.Thread.Mutex{},
            .join_codes = std.ArrayList(JoinCode).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        for (self.join_codes.items) |join_code| {
            join_code.deinit();
        }
        self.join_codes.deinit();
    }
};
