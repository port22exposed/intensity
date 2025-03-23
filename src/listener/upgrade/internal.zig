const std = @import("std");
const zap = @import("zap");

const global = @import("../../global.zig");
const utility = @import("../../utility.zig");

const WebSocketHandler = @import("../../websockets/context_manager.zig").WebSocketHandler;
const allocator = @import("../../main.zig").allocator;

const UpgradeError = error{ IllegalProtocol, IllegalRequest, AllocationException, ContextCreationException, WebSocketHandlerUpgradeFail };

pub fn internal_upgrade(r: zap.Request, target_protocol: []const u8) UpgradeError!void {
    const context_manager = global.getContextManager();

    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        return error.IllegalProtocol;
    }

    var context = context_manager.newContext() catch {
        return error.ContextCreationException;
    };

    WebSocketHandler.upgrade(r.h, &context.settings) catch {
        return error.WebSocketHandlerUpgradeFail;
    };
}
