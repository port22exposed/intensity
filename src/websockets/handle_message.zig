const std = @import("std");

const zap = @import("zap");
const WebSockets = zap.WebSockets;

const allocator = @import("../main.zig").allocator;

const context_manager = @import("./context_manager.zig");
const json = @import("./json.zig");

pub fn handler(
    context: ?*context_manager.Context,
    handle: WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) void {
    _ = handle;

    const log = std.log.scoped(.websocket_message);

    if (context) |ctx| {
        if (!is_text) {
            log.warn("invalid packet received from, {s}", .{ctx.username});
            return;
        }

        const isJson = std.json.validate(allocator, message) catch |err| {
            log.warn("failed to validate JSON: {}", .{err});
            return;
        };

        if (!isJson) {
            log.warn("received malformed packet from {s}, invalid JSON", .{ctx.username});
            return;
        }

        const parsedJsonArena = std.json.parseFromSlice(std.json.Value, allocator, message, .{}) catch |err| {
            log.warn("failed to parse JSON: {}", .{err});
            return;
        };
        defer parsedJsonArena.deinit();

        const parsedJson = parsedJsonArena.value;

        switch (parsedJson) {
            .object => |obj| {
                const packetType = json.getValue([]const u8, obj, "type") catch {
                    return;
                };

                if (std.mem.eql(u8, packetType, "keyExchange")) {
                    @import("./handlers/keyExchange.zig").handle_message(ctx, obj) catch |err| {
                        log.err("failed to handle packet from {s}: {}", .{err});
                        return;
                    };
                }
            },
            else => log.warn("malformed packet from {s}, invalid JSON", .{ctx.username}),
        }
    }
}
