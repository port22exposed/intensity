const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

const ws = @import("../ws.zig");

pub fn handle_message(
    context: ?*ws.Context,
    handle: WebSockets.WsHandle,
    object: std.json.ObjectMap,
) !void {
    _ = context;
    _ = handle;
    _ = object;
}
