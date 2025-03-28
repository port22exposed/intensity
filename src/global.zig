const std = @import("std");
const utility = @import("./utility.zig");

const State = @import("./state.zig").State;
const ContextManager = @import("./websockets/context_manager.zig").ContextManager;

var global_state: State = undefined;
var global_context_manager: ContextManager = undefined;

pub fn initState(allocator: std.mem.Allocator) *State {
    global_state = State.init(allocator);
    return &global_state;
}

pub fn getState() *State {
    return &global_state;
}

pub fn initContextManager(allocator: std.mem.Allocator) *ContextManager {
    global_context_manager = ContextManager.init(allocator);
    return &global_context_manager;
}

pub fn getContextManager() *ContextManager {
    return &global_context_manager;
}

pub const CHAT_CHANNEL = "fat_succ";
