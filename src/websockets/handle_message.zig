const zap = @import("zap");
const WebSockets = zap.WebSockets;

const context_manager = @import("./context_manager.zig");

pub fn handler(
    context: ?*context_manager.Context,
    handle: WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) void {
    _ = context;
    _ = handle;
    _ = message;
    _ = is_text;
}
