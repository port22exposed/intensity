const std = @import("std");
const zap = @import("zap");

const WebSockets = zap.WebSockets;

const global = @import("../global.zig");
const json = @import("../json.zig");
const ws = @import("../ws.zig");

const CommandName = enum {
    transfer,
    status,
    host,
    kick,
    deop,
    op,
};

pub fn handle_message(
    context: *ws.Context,
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

    const target = json.getValue([]const u8, object, "target") catch "";

    switch (command) {
        .status => {
            const notice = std.fmt.allocPrint(allocator, "your permission level is: {}", .{context.permission}) catch |err| {
                std.log.err("failed to allocate notice message: {}", .{err});
                return;
            };
            defer allocator.free(notice);

            GlobalContextManager.systemMessage(.{ .context = context, .message = notice });
        },
        .host => {
            for (GlobalContextManager.contexts.items) |ctx| {
                if (ctx.permission >= 2) {
                    const notice = std.fmt.allocPrint(allocator, "the current host is \"{s}\"", .{ctx.username}) catch |err| {
                        std.log.err("failed to allocate notice message: {}", .{err});
                        return;
                    };
                    defer allocator.free(notice);

                    GlobalContextManager.systemMessage(.{ .context = context, .message = notice });
                }
            }
        },
        .kick => {
            if (context.permission < 1) {
                GlobalContextManager.systemMessage(.{ .context = context, .message = "insufficient permissions to run command" });
                return error.InvalidPermissions;
            }

            const questionableTargetContext = GlobalContextManager.getContext(target);

            if (questionableTargetContext) |targetContext| {
                if (targetContext.permission >= context.permission) {
                    GlobalContextManager.systemMessage(.{ .context = context, .message = "you cannot kick users with the same or higher permission levels as you!" });
                    return error.InvalidPermissions;
                }

                if (targetContext.handle) |targetHandle| {
                    GlobalState.block_ip(targetContext.ip);
                    ws.WebSocketHandler.close(targetHandle);

                    const notice = std.fmt.allocPrint(allocator, "{s} kicked {s}", .{ context.username, target }) catch |err| {
                        std.log.err("failed to allocate notice message: {}", .{err});
                        return;
                    };
                    defer allocator.free(notice);

                    GlobalContextManager.systemMessage(.{ .message = notice });
                    std.log.info("{s}", .{notice});
                }
            }
        },
        .op => {
            if (context.permission < 2) {
                GlobalContextManager.systemMessage(.{ .context = context, .message = "insufficient permissions to run command" });
                return error.InvalidPermissions;
            }

            const questionableTargetContext = GlobalContextManager.getContext(target);

            if (questionableTargetContext) |targetContext| {
                targetContext.permission = 1;

                const notice = std.fmt.allocPrint(allocator, "{s} was made an operator by {s}", .{ target, context.username }) catch |err| {
                    std.log.err("failed to allocate notice message: {}", .{err});
                    return;
                };
                defer allocator.free(notice);

                GlobalContextManager.systemMessage(.{ .message = notice });
                std.log.info("{s}", .{notice});
            }
        },
        .deop => {
            if (context.permission < 2) {
                GlobalContextManager.systemMessage(.{ .context = context, .message = "insufficient permissions to run command" });
                return error.InvalidPermissions;
            }

            const questionableTargetContext = GlobalContextManager.getContext(target);

            if (questionableTargetContext) |targetContext| {
                targetContext.permission = 0;

                const notice = std.fmt.allocPrint(allocator, "{s} removed operator status from {s}", .{ context.username, target }) catch |err| {
                    std.log.err("failed to allocate notice message: {}", .{err});
                    return;
                };
                defer allocator.free(notice);

                GlobalContextManager.systemMessage(.{ .message = notice });
                std.log.info("{s}", .{notice});
            }
        },
        .transfer => {
            if (context.permission < 2) {
                GlobalContextManager.systemMessage(.{ .context = context, .message = "insufficient permissions to run command" });
                return error.InvalidPermissions;
            }

            const questionableTargetContext = GlobalContextManager.getContext(target);

            if (questionableTargetContext) |targetContext| {
                targetContext.permission = 2;
                context.permission = 1;

                const notice = std.fmt.allocPrint(allocator, "{s} transferred ownership of the group to {s}", .{ context.username, target }) catch |err| {
                    std.log.err("failed to allocate notice message: {}", .{err});
                    return;
                };
                defer allocator.free(notice);

                GlobalContextManager.systemMessage(.{ .message = notice });
                std.log.info("{s}", .{notice});
            }
        },
    }
}
