const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

const utility = @import("../utility.zig");
const global = @import("../global.zig");

pub const WebSocketHandler = WebSockets.Handler(Context);

pub const Context = struct {
    username: []u8,
    handle: ?WebSockets.WsHandle,
    permission: u8,
    subscribe_args: WebSocketHandler.SubscribeArgs,
    settings: WebSocketHandler.WebSocketSettings,
};

pub const ContextList = std.ArrayList(*Context);

pub const ContextManager = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},
    contexts: ContextList = undefined,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
    ) Self {
        return .{
            .allocator = allocator,
            .contexts = ContextList.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.contexts.items) |ctx| {
            self.allocator.free(ctx.username);
            self.allocator.destroy(ctx);
        }
        self.contexts.deinit();
    }

    fn generateUniqueUsername(self: *Self) ![]u8 {
        self.mutex.lock();
        defer self.mutex.unlock();

        var attempts: usize = 0;
        const max_attempts: usize = 10;

        while (attempts < max_attempts) : (attempts += 1) {
            const candidate = try utility.randomAlphanumericString(self.allocator, 8);

            var is_taken = false;
            for (self.contexts.items) |ctx| {
                if (std.mem.eql(u8, ctx.username, candidate)) {
                    is_taken = true;
                    break;
                }
            }

            if (!is_taken) {
                return candidate;
            }

            self.allocator.free(candidate);
        }

        return error.UsernameGenerationFailed;
    }

    pub fn sendPacket(self: *Self, name: []const u8, data: anytype) !void {
        const json = .{ .type = name, .data = data };
        const encodedPacket = try std.json.stringifyAlloc(self.allocator, json, .{});
        defer self.allocator.free(encodedPacket);
        WebSocketHandler.publish(.{
            .channel = global.chat_channel,
            .message = encodedPacket,
            .is_json = true,
        });
    }

    pub fn newContext(self: *Self) !*Context {
        self.mutex.lock();
        defer self.mutex.unlock();

        const username = try self.generateUniqueUsername();
        errdefer self.allocator.free(username);

        const ctx = try self.allocator.create(Context);

        ctx.* = .{
            .username = username,
            .handle = null,
            .permission = if (self.contexts.items.len == 0) 255 else 0,
            // used in subscribe()
            .subscribe_args = .{
                .channel = global.chat_channel,
                .force_text = true,
                .context = ctx,
            },
            // used in upgrade()
            .settings = .{
                .on_open = @import("./on_open.zig").handler,
                .on_close = @import("./on_close.zig").handler,
                .on_message = @import("./handle_message.zig").handler,
                .context = ctx,
            },
        };

        try self.contexts.append(ctx);

        return ctx;
    }
};
