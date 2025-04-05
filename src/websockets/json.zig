const std = @import("std");

pub fn getValue(comptime T: type, object: std.json.ObjectMap, key: []const u8) !T {
    const value = object.get(key) orelse return error.KeyNotFound;

    return switch (value) {
        .integer => |i| if (T == 64) i else error.TypeMismatch,
        .float => |f| if (T == f64) f else error.TypeMismatch,
        .string => |s| if (T == []const u8) s else error.TypeMismatch,
        .bool => |b| if (T == bool) b else error.TypeMismatch,
        .object => |o| if (T == std.json.ObjectMap) o else error.TypeMismatch,
        else => error.TypeMismatch,
    };
}
