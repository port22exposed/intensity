const std = @import("std");
const zap = @import("zap");

const validation = @import("./validation.zig");

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

    pub fn block_ip(self: *Self, r: zap.Request) void {
        const ip = r.getHeader("cf-connecting-ip") orelse r.getHeader("x-forwarded-for") orelse r.getHeader("x-real-ip") orelse "unknown";

        if (std.mem.eql(u8, ip, "unknown")) {
            std.log.warn("received illegal websocket upgrade request: IP address unobtainable", .{});
            validation.deny_request(r);
            return;
        }

        const ipNonTemp: []u8 = self.allocator.dupe(u8, ip) catch |err| {
            std.log.err("Failed to duplicate IP address within memory: {}", .{err});
            validation.deny_request(r);
            return;
        };

        self.blocked_ips.append(ipNonTemp) catch |err| {
            std.log.err("Failed to append IP to blocked_ips: {}", .{err});
            self.allocator.free(ipNonTemp);
            validation.deny_request(r);
        };
    }
};
