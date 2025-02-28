const global = @import("./global.zig");
const json = @import("./json.zig");

const packetHandlers = .{ .command = @import("./incoming/command.zig"), .message = @import("./incoming/message.zig") };

const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

pub const WebSocketHandler = WebSockets.Handler(Context);

pub const Context = struct {
    username: []const u8,
    channel: []const u8,
    handle: ?WebSockets.WsHandle,
    permission: u8, // 0 = regular user, 1 = operator, 2 = owner
    // we need to hold on to them and just re-use them for every incoming
    // connection
    subscribeArgs: WebSocketHandler.SubscribeArgs,
    settings: WebSocketHandler.WebSocketSettings,
};

pub const ContextList = std.ArrayList(*Context);

pub const ContextManager = struct {
    allocator: std.mem.Allocator,
    lock: std.Thread.Mutex = .{},
    contexts: ContextList = undefined,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
    ) Self {
        return .{
            .allocator = allocator,
            .contexts = ContextList.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.contexts.items) |ctx| {
            self.allocator.free(ctx.username);
        }
        self.contexts.deinit();
    }

    pub fn availableName(self: *Self, username: []u8) !bool {
        const lowercaseNameToCompare = try std.ascii.allocLowerString(self.allocator, username);
        defer self.allocator.free(lowercaseNameToCompare);

        for (self.contexts.items) |context| {
            const lowercaseName = try std.ascii.allocLowerString(self.allocator, context.username);
            defer self.allocator.free(lowercaseName);
            if (std.mem.eql(u8, lowercaseName, lowercaseNameToCompare)) {
                return false;
            }
        }

        return true;
    }

    pub fn newContext(self: *Self, username: []u8) !*Context {
        errdefer self.allocator.free(username);

        if (try self.availableName(username)) {
            const ctx = try self.allocator.create(Context);
            ctx.* = .{
                .username = username,
                .channel = "comms",
                .handle = null,
                .permission = if (self.contexts.items.len == 0) 2 else 0,
                // used in subscribe()
                .subscribeArgs = .{
                    .channel = "comms",
                    .force_text = true,
                    .context = ctx,
                },
                // used in upgrade()
                .settings = .{
                    .on_open = on_open_websocket,
                    .on_close = on_close_websocket,
                    .on_message = handle_websocket_message,
                    .context = ctx,
                },
            };
            try self.contexts.append(ctx);
            return ctx;
        } else {
            return error.NameUnavailable;
        }
    }

    pub fn systemMessage(self: *Self, options: struct {
        payload: []const u8,
        handle: ?WebSockets.WsHandle = null,
    }) void {
        const log = std.log.scoped(.systemMessage);

        const messagePacket = .{ .type = "systemMessage", .data = .{ .message = options.payload } };

        const jsonString = std.json.stringifyAlloc(self.allocator, messagePacket, .{}) catch |err| {
            log.err("error allocating memory for system message packet: {}", .{err});
            return;
        };
        defer self.allocator.free(jsonString);

        if (options.handle) |handle| {
            WebSocketHandler.write(handle, jsonString, true) catch |err| {
                log.err("failed writing to specified handle: {}", .{err});
                return;
            };
        } else {
            WebSocketHandler.publish(.{ .channel = "comms", .message = jsonString });
        }
    }
};

fn on_open_websocket(context: ?*Context, handle: WebSockets.WsHandle) void {
    const log = std.log.scoped(.websocket_open);

    if (context) |ctx| {
        _ = WebSocketHandler.subscribe(handle, &ctx.subscribeArgs) catch |err| {
            log.err("error opening websocket: {any}", .{err});
            return;
        };

        ctx.handle = handle;

        const GlobalContextManager = global.get_context_manager();
        defer GlobalContextManager.lock.unlock();

        const allocator = GlobalContextManager.allocator;

        const message = std.fmt.allocPrint(allocator, "{s} has joined the chat.", .{ctx.username}) catch |err| {
            log.err("failed to allocate system message: {}", .{err});
            return;
        };
        defer allocator.free(message);

        GlobalContextManager.systemMessage(.{ .payload = message });

        const updatePacket = .{ .type = "update", .data = .{ .userCount = GlobalContextManager.contexts.items.len } };

        const jsonString = std.json.stringifyAlloc(allocator, updatePacket, .{}) catch |err| {
            log.err("error allocating memory for update packet: {}", .{err});
            WebSocketHandler.close(handle);
            return;
        };
        defer allocator.free(jsonString);

        WebSocketHandler.publish(.{ .channel = ctx.channel, .message = jsonString });
    }
}

fn on_close_websocket(context: ?*Context, uuid: isize) void {
    _ = uuid;
    const log = std.log.scoped(.websocket_close);

    if (context) |ctx| {
        const GlobalContextManager = global.get_context_manager();
        defer GlobalContextManager.lock.unlock();

        const contexts = GlobalContextManager.contexts.items;

        const updatePacket = .{ .type = "update", .data = .{ .userCount = contexts.len } };

        const allocator = GlobalContextManager.allocator;

        const message = std.fmt.allocPrint(allocator, "{s} has left the chat.", .{ctx.username}) catch |err| {
            log.err("failed to allocate system message: {}", .{err});
            return;
        };
        defer allocator.free(message);

        GlobalContextManager.systemMessage(.{ .payload = message });

        const jsonString = std.json.stringifyAlloc(allocator, updatePacket, .{}) catch |err| {
            log.err("error allocating memory for update packet: {}", .{err});
            return;
        };
        defer allocator.free(jsonString);

        WebSocketHandler.publish(.{ .channel = ctx.channel, .message = jsonString });

        for (contexts, 0..) |item, index| {
            if (item == ctx) {
                if (ctx.permission == 2) {
                    if (index + 1 < contexts.len) {
                        contexts[index + 1].permission = 2;
                    }
                }
                allocator.free(ctx.username);
                const removedItem = GlobalContextManager.contexts.orderedRemove(index);
                allocator.destroy(removedItem);
                break;
            }
        }
    }
}

fn handle_websocket_message(
    context: ?*Context,
    handle: WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) void {
    const log = std.log.scoped(.websocket_message);

    if (context) |ctx| {
        const allocator = std.heap.page_allocator;

        // ensure the packet isn't malformed
        const isJson = std.json.validate(allocator, message) catch |err| {
            log.err("failed to validate JSON: {}", .{err});
            return;
        };

        if (!isJson or !is_text) {
            log.warn("received malformed packet from {s}, invalid JSON", .{ctx.username});
            return;
        }

        const parsedJsonArena = std.json.parseFromSlice(std.json.Value, allocator, message, .{}) catch |err| {
            log.err("failed to parse JSON: {}", .{err});
            return;
        };
        defer parsedJsonArena.deinit();
        const parsedJson = parsedJsonArena.value;

        switch (parsedJson) {
            .object => |obj| {
                const packetType = json.getValue([]const u8, obj, "type") catch {
                    return;
                };

                if (std.mem.eql(u8, packetType, "command")) {
                    packetHandlers.command.handle_message(ctx, handle, obj) catch |err| {
                        log.warn("packet from {s} failed to be handled: {}", .{ ctx.username, err });
                        return;
                    };
                } else if (std.mem.eql(u8, packetType, "message")) {
                    packetHandlers.message.handle_message(ctx, handle, obj) catch |err| {
                        log.warn("packet from {s} failed to be handled: {}", .{ ctx.username, err });
                        return;
                    };
                } else {
                    log.warn("packet dropped from {s}, invalid packet type: {s}", .{ ctx.username, packetType });
                }
            },
            else => log.warn("malformed packet from {s}, invalid JSON", .{ctx.username}),
        }
    }
}
