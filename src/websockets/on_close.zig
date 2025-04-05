const std = @import("std");

const allocator = @import("../main.zig").allocator;
const global = @import("../global.zig");
const context_manager = @import("./context_manager.zig");

pub fn handler(context: ?*context_manager.Context, uuid: isize) void {
    _ = uuid;
    const log = std.log.scoped(.websocket_close);

    if (context) |ctx| {
        const global_context_manager = global.getContextManager();
        global_context_manager.mutex.lock();
        defer global_context_manager.mutex.unlock();

        const exitMessage = std.fmt.allocPrint(allocator, "{s} has left the chat.", .{ctx.username}) catch "New user joined the chat.";
        defer allocator.free(exitMessage);

        global_context_manager.systemMessage(exitMessage, null) catch |err| {
            log.err("failed to send system message: {any}", .{err});
            return;
        };

        const contexts = global_context_manager.contexts.items;

        for (contexts, 0..) |item, index| {
            if (item == ctx) {
                if (ctx.permission == 255) {
                    if (index + 1 < contexts.len) {
                        contexts[index + 1].permission = 255;
                    }
                }

                global_context_manager.freeContext(ctx);
                const removedItem = global_context_manager.contexts.orderedRemove(index);
                global_context_manager.allocator.destroy(removedItem);
                break;
            }
        }

        global_context_manager.sendPacket("userCountChange", .{ .userCount = global_context_manager.contexts.items.len }, null) catch |err| {
            log.err("failed to send update packet: {any}", .{err});
            return;
        };
    }
}
