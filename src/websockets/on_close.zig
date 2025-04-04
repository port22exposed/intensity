const std = @import("std");

const global = @import("../global.zig");
const context_manager = @import("./context_manager.zig");

pub fn handler(context: ?*context_manager.Context, uuid: isize) void {
    _ = uuid;
    // const log = std.log.scoped(.websocket_close);

    if (context) |ctx| {
        const global_context_manager = global.getContextManager();
        global_context_manager.mutex.lock();
        defer global_context_manager.mutex.unlock();

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
    }
}
