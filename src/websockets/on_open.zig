const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

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
    }
}
