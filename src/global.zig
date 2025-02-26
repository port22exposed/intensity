const std = @import("std");

var GlobalContextManager: ws.ContextManager = undefined;

const ws = @import("./ws.zig");

pub fn init_context_manager(allocator: std.mem.Allocator) *ws.ContextManager {
    GlobalContextManager = ws.ContextManager.init(allocator);
    return &GlobalContextManager;
}

pub fn get_context_manager() *ws.ContextManager {
    GlobalContextManager.lock.lock(); // Caller must unlock the GCM upon finishing with it
    return &GlobalContextManager;
}
