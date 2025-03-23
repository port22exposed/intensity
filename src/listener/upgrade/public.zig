const std = @import("std");
const zap = @import("zap");

const response = @import("../response.zig");

const internal_upgrade = @import("./internal.zig").internal_upgrade;

pub fn on_upgrade(r: zap.Request, target_protocol: []const u8) void {
    const log = std.log.scoped(.websocket_upgrade);

    internal_upgrade(r, target_protocol) catch |err| {
        switch (err) {
            error.IllegalProtocol => log.warn("received illegal protocol: {s}", .{target_protocol}),
            error.IllegalRequest => log.warn("received illegal request", .{}),
            error.AllocationException => log.err("failed to allocate memory", .{}),
            error.ContextCreationException => log.err("error creating context", .{}),
            error.WebSocketHandlerUpgradeFail => log.err("error in WebSocketHandler.upgrade(): {any}", .{err}),
        }
        return response.denyRequest(r);
    };
}
