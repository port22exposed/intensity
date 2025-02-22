const global = @import("./global.zig");

const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

pub const WebSocketHandler = WebSockets.Handler(Context);

pub const Context = struct {
    username: []const u8,
    channel: []const u8,
    host: bool,
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
        self.lock.lock();
        defer self.lock.unlock();

        if (try self.availableName(username)) {
            const GlobalContextManager = global.get_context_manager();

            const ctx = try self.allocator.create(Context);
            ctx.* = .{
                .username = username,
                .channel = "comms",
                .host = GlobalContextManager.contexts.items.len == 0,
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
            return error{NameUnavailable}.NameUnavailable;
        }
    }
};

fn on_open_websocket(context: ?*Context, handle: WebSockets.WsHandle) void {
    if (context) |ctx| {
        _ = WebSocketHandler.subscribe(handle, &ctx.subscribeArgs) catch |err| {
            std.log.err("error opening websocket: {any}", .{err});
            return;
        };

        const GlobalContextManager = global.get_context_manager();

        const updatePacket = .{ .type = "update", .data = .{ .userCount = GlobalContextManager.contexts.items.len, .userJoining = ctx.username } };

        const allocator = std.heap.page_allocator;

        const jsonString = std.json.stringifyAlloc(allocator, updatePacket, .{}) catch |err| {
            std.log.err("error allocating memory for update packet: {}", .{err});
            WebSocketHandler.close(handle);
            return;
        };
        defer allocator.free(jsonString);

        WebSocketHandler.publish(.{ .channel = ctx.channel, .message = jsonString });
    }
}

fn on_close_websocket(context: ?*Context, uuid: isize) void {
    _ = uuid;
    if (context) |ctx| {
        const GlobalContextManager = global.get_context_manager();
        const contexts = GlobalContextManager.contexts.items;
        for (contexts, 0..) |item, index| {
            if (item == ctx) {
                if (ctx.host) {
                    if (index + 1 < contexts.len) {
                        contexts[index + 1].host = true;
                        std.log.info("{}", .{contexts[index + 1]});
                    }
                }
                _ = GlobalContextManager.contexts.orderedRemove(index);
                break;
            }
        }

        const updatePacket = .{ .type = "update", .data = .{ .userCount = GlobalContextManager.contexts.items.len, .userLeaving = ctx.username } };

        const allocator = std.heap.page_allocator;

        const jsonString = std.json.stringifyAlloc(allocator, updatePacket, .{}) catch |err| {
            std.log.err("error allocating memory for update packet: {}", .{err});
            return;
        };
        defer allocator.free(jsonString);

        WebSocketHandler.publish(.{ .channel = ctx.channel, .message = jsonString });
    }
}

fn handle_websocket_message(
    context: ?*Context,
    handle: WebSockets.WsHandle,
    message: []const u8,
    is_text: bool,
) void {
    _ = is_text;
    _ = message;
    _ = handle;
    if (context) |ctx| {
        WebSocketHandler.publish(.{ .channel = ctx.channel, .message = "hello world!" });
        // // send message
        // const buflen = 128; // arbitrary len
        // var buf: [buflen]u8 = undefined;

        // const format_string = "{s}: {s}";
        // const fmt_string_extra_len = 2; // ": " between the two strings
        // //
        // const max_msg_len = buflen - ctx.username.len - fmt_string_extra_len;
        // if (max_msg_len > 0) {
        //     // there is space for the message, because the user name + format
        //     // string extra do not exceed the buffer now, let's check: do we
        //     // need to trim the message?
        //     var trimmed_message: []const u8 = message;
        //     if (message.len > max_msg_len) {
        //         trimmed_message = message[0..max_msg_len];
        //     }
        //     const chat_message = std.fmt.bufPrint(
        //         &buf,
        //         format_string,
        //         .{ ctx.username, trimmed_message },
        //     ) catch unreachable;

        //     // send notification to all others
        //     WebSocketHandler.publish(
        //         .{ .channel = ctx.channel, .message = chat_message },
        //     );
        //     std.log.info("{s}", .{chat_message});
        // } else {
        //     std.log.warn(
        //         "Username is very long, cannot deal with that size: {d}",
        //         .{ctx.username.len},
        //     );
        // }
    }
}
