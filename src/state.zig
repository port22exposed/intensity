const std = @import("std");
const zap = @import("zap");

const validation = @import("./validation.zig");

fn get_ip(r: zap.Request) ?[]const u8 {
    const ip = r.getHeader("cf-connecting-ip") orelse r.getHeader("x-forwarded-for") orelse r.getHeader("x-real-ip") orelse null;

    return ip;
}

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

    pub fn is_ip_blocked(self: *Self, r: zap.Request) bool {
        const questionableIp = get_ip(r);

        if (questionableIp) |clientIp| {
            for (self.blocked_ips.items) |ip| {
                if (std.mem.eql(u8, ip, clientIp)) {
                    return true;
                }
            }
        }

        return false;
    }

    pub fn block_ip(self: *Self, r: zap.Request) void {
        const questionableIp = get_ip(r);

        if (questionableIp) |clientIp| {
            const ownedIp = self.allocator.dupe(u8, clientIp) catch |err| {
                std.log.err("failed to convert the user's IP address into owned memory: {}", .{err});
                return;
            };
            self.blocked_ips.append(ownedIp) catch |err| {
                std.log.err("failed to append client IP to blocked_ips array: {}", .{err});
            };
        } else {
            std.log.err("failed to obtain client IP address from headers!", .{});
        }

        return;
    }
};
