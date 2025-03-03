const std = @import("std");
const zap = @import("zap");

const validation = @import("./validation.zig");

fn get_ip(r: zap.Request) ?[]const u8 {
    const ip = r.getHeader("cf-connecting-ip") orelse r.getHeader("x-forwarded-for") orelse r.getHeader("x-real-ip") orelse null;

    return ip;
}

pub const State = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    blocked_ips: std.ArrayList([]u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .mutex = std.Thread.Mutex{},
            .blocked_ips = std.ArrayList([]u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.blocked_ips.deinit();
    }

    pub fn is_ip_blocked(self: *Self, clientIp: []const u8) bool {
        for (self.blocked_ips.items) |ip| {
            if (std.mem.eql(u8, ip, clientIp)) {
                return true;
            }
        }

        return false;
    }

    pub fn block_ip(self: *Self, clientIp: []const u8) void {
        const ownedIp = self.allocator.dupe(u8, clientIp) catch |err| {
            std.log.err("failed to clone the user's IP address in memory: {}", .{err});
            return;
        };
        self.blocked_ips.append(ownedIp) catch |err| {
            std.log.err("failed to append client IP to blocked_ips array: {}", .{err});
        };
    }
};
