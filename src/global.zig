const std = @import("std");
const utility = @import("./utility.zig");

const State = @import("./state.zig").State;

var global_state: State = undefined;

pub fn initState(allocator: std.mem.Allocator) *State {
    global_state = State.init(allocator);
    return &global_state;
}

pub fn getState() *State {
    return &global_state;
}

pub const chat_channel = "fat_succ";
