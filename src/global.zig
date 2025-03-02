const std = @import("std");

const state = @import("./state.zig").State;
const ws = @import("./ws.zig");

var GlobalContextManager: ws.ContextManager = undefined;
var GlobalState: state = undefined;

pub fn init_context_manager(allocator: std.mem.Allocator) *ws.ContextManager {
    GlobalContextManager = ws.ContextManager.init(allocator);
    return &GlobalContextManager;
}

pub fn get_context_manager() *ws.ContextManager {
    GlobalContextManager.mutex.lock(); // Caller must unlock upon finishing with it
    return &GlobalContextManager;
}

pub fn init_state(allocator: std.mem.Allocator) *state {
    GlobalState = state.init(allocator);
    return &GlobalState;
}

pub fn get_state() *state {
    GlobalState.mutex.lock(); // Caller must unlock upon finishing with it
    return &GlobalState;
}
