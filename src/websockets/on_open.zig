const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

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
    }
}
