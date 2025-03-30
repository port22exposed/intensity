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

    pub fn sendPacket(self: *Self, name: []const u8, data: anytype, context: ?Context) !void {
        const json = .{ .type = name, .data = data };
        const encodedPacket = try std.json.stringifyAlloc(self.allocator, json, .{});
        defer self.allocator.free(encodedPacket);

        if (context) |ctx| {
            if (ctx.handle) |handle| {
                try WebSocketHandler.write(handle, encodedPacket, true);
            }
        } else {
            WebSocketHandler.publish(.{
                .channel = global.CHAT_CHANNEL,
                .message = encodedPacket,
                .is_json = false,
            });
        }
    }

    pub fn newContext(self: *Self, username: []u8) !*Context {
        self.mutex.lock();
        defer self.mutex.unlock();

        const owned_username = try self.allocator.dupe(u8, username);

        const ctx = try self.allocator.create(Context);

        ctx.* = .{
            .username = owned_username,
            .handle = null,
            .permission = if (self.contexts.items.len == 0) 255 else 0,
            // used in subscribe()
            .subscribe_args = .{
                .channel = global.CHAT_CHANNEL,
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
