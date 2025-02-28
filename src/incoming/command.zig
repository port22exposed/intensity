const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

const global = @import("../global.zig");
const json = @import("../json.zig");
const ws = @import("../ws.zig");

const CommandName = enum {
    kick,
};

pub fn handle_message(
    context: *ws.Context,
    handle: WebSockets.WsHandle,
    object: std.json.ObjectMap,
) !void {
    const GlobalContextManager = global.get_context_manager();
    defer GlobalContextManager.lock.unlock();

    const contexts = GlobalContextManager.contexts.items;

    const commandName = json.getValue([]const u8, object, "name") catch {
        return error.NoCommandProvided;
    };

    const command: CommandName = std.meta.stringToEnum(CommandName, commandName) orelse {
        return error.InvalidCommand;
    };

    switch (command) {
        .kick => {
            if (context.permission <= 1) {
                GlobalContextManager.systemMessage(.{ .handle = handle, .payload = "insufficient permissions to run command" });
                return error.InvalidPermissions;
            }

            const target = json.getValue([]const u8, object, "target") catch {
                return error.InvalidCommandData;
            };

            var found = false;

            for (contexts) |item| {
                if (std.mem.eql(u8, target, item.username)) {
                    if (item.handle) |targetHandle| {
                        found = true;
                        ws.WebSocketHandler.close(targetHandle);
                    }
                }
            }

            if (found) {
                std.log.info("{s} was kicked by {s}", .{ target, context.username });
            }
        },
    }
}
