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
    defer GlobalContextManager.mutex.unlock();

    const GlobalState = global.get_state();
    defer GlobalState.mutex.unlock();

    const allocator = GlobalContextManager.allocator;

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

            const questionableTargetContext = GlobalContextManager.getContext(target);

            if (questionableTargetContext) |targetContext| {
                if (targetContext.handle) |targetHandle| {
                    GlobalState.block_ip(targetContext.ip);
                    ws.WebSocketHandler.close(targetHandle);

                    const notice = std.fmt.allocPrint(allocator, "{s} kicked {s}", .{ context.username, target }) catch |err| {
                        std.log.err("failed to allocate kick notice message: {}", .{err});
                        return;
                    };
                    defer allocator.free(notice);

                    GlobalContextManager.systemMessage(.{ .payload = notice });
                    std.log.info("{s}", .{notice});
                }
            }
        },
    }
}
