const std = @import("std");

const global = @import("../global.zig");
const context_manager = @import("./context_manager.zig");

pub fn handler(context: ?*context_manager.Context, uuid: isize) void {
    _ = context;
    _ = uuid;
}
