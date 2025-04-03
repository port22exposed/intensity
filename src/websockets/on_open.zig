const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

const allocator = @import("../main.zig").allocator;
const global = @import("../global.zig");
const context_manager = @import("./context_manager.zig");

const WebSocketHandler = context_manager.WebSocketHandler;

pub fn handler(context: ?*context_manager.Context, handle: WebSockets.WsHandle) void {
    const log = std.log.scoped(.websocket_);

    if (context) |ctx| {
        _ = WebSocketHandler.subscribe(handle, &ctx.subscribe_args) catch |err| {
            log.err("error opening websocket: {any}", .{err});
            return;
        };

        ctx.handle = handle;

        const global_context_manager = global.getContextManager();
        global_context_manager.sendPacket("pong", .{ .username = ctx.username }, handle) catch |err| {
            log.err("failed to send pong packet: {any}", .{err});
            return;
        };

        global_context_manager.sendPacket("update", .{ .userCount = global_context_manager.contexts.items.len }, null) catch |err| {
            log.err("failed to send update packet: {any}", .{err});
            return;
        };

        const joinMessage = std.fmt.allocPrint(allocator, "{s} has joined the chat.", .{ctx.username}) catch "New user joined the chat.";
        defer allocator.free(joinMessage);

        global_context_manager.systemMessage(joinMessage, null) catch |err| {
            log.err("failed to send system message: {any}", .{err});
            return;
        };
    }
}
