const std = @import("std");

const zap = @import("zap");
const WebSockets = zap.WebSockets;

const context_manager = @import("../context_manager.zig");
const json = @import("../json.zig");

pub fn handle_message(context: *context_manager.Context, object: std.json.ObjectMap) !void {
    const key = try json.getValue([]const u8, object, "stage");

    if (std.mem.eql(u8, key, "publicKeyDisclosure")) {
        const publicKey = try json.getValue([]const u8, object, "key");
        context.publicKey = publicKey;
    }
}
