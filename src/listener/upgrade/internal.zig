const std = @import("std");
const zap = @import("zap");

const codes = @import("../../codes.zig");
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

    const provided_join_code = r.getParamSlice("auth") orelse {
        return error.IllegalRequest;
    };

    const state = global.getState();
    state.mutex.lock();
    defer state.mutex.unlock();

    var questionable_join_code_struct: ?codes.JoinCode = null;

    for (state.join_codes.items, 0..) |join_code, index| {
        if (std.mem.eql(u8, provided_join_code, join_code.code)) {
            questionable_join_code_struct = state.join_codes.swapRemove(index);
            break;
        }
    }

    if (questionable_join_code_struct) |join_code_struct| {
        defer join_code_struct.deinit();

        var context = context_manager.newContext(join_code_struct.username) catch {
            return error.ContextCreationException;
        };

        WebSocketHandler.upgrade(r.h, &context.settings) catch {
            return error.WebSocketHandlerUpgradeFail;
        };
    } else {
        return error.IllegalRequest;
    }
}
