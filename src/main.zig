const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const global = @import("./global.zig");

const Allocator = if (builtin.mode == .Debug)
    std.heap.GeneralPurposeAllocator(.{ .thread_safe = true })
else
    std.heap.SmpAllocator;

var allocator_state = if (builtin.mode == .Debug)
    Allocator{}
else
    null;

pub const allocator = if (builtin.mode == .Debug)
    allocator_state.allocator()
else
    std.heap.smp_allocator;

pub fn main() !void {
    defer {
        if (builtin.mode == .Debug) {
            const deinit_status = allocator_state.deinit();
            if (deinit_status == .leak) std.log.debug("GPA detected a memory leak!", .{});
        }
    }

    const state = global.initState(allocator);
    defer state.deinit();

    var args_it = try std.process.argsWithAllocator(allocator);
    defer args_it.deinit();

    var port: usize = 3000;
    var frontendDirectory: []const u8 = "public";
    var threads: u8 = 2;
    var workers: u8 = 1;

    while (args_it.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--port=")) {
            if (std.fmt.parseUnsigned(usize, arg[7..], 0)) |the_port| {
                port = the_port;
                std.log.debug("port, huh I've heard that somewhere.... [EASTER EGG, DO NOT DEBUG]", .{});
            } else |_| {
                std.log.warn("Invalid port number. Using default port {}\n", .{port});
            }
        }

        if (std.mem.startsWith(u8, arg, "--frontend=")) {
            frontendDirectory = arg[11..];
        }

        if (std.mem.startsWith(u8, arg, "--threads=")) {
            if (std.fmt.parseUnsigned(u8, arg[10..], 0)) |the_threads| {
                threads = the_threads;
            } else |_| {
                std.log.warn("Invalid thread count (range of 1-255). Using default of {}\n", .{threads});
            }
        }

        if (std.mem.startsWith(u8, arg, "--workers=")) {
            if (std.fmt.parseUnsigned(u8, arg[10..], 0)) |the_workers| {
                workers = the_workers;
            } else |_| {
                std.log.warn("Invalid worker count (range of 1-255). Using default of {}\n", .{workers});
            }
        }
    }

    var http = zap.HttpListener.init(.{
        .port = port,
        .on_request = @import("./listener/request/public.zig").on_request,
        .max_clients = 1024,
        .max_body_size = 1 * 1024,
        .ws_timeout = 60, // disconnects, if no response in 60s
        .public_folder = frontendDirectory,
        .log = builtin.mode == .Debug,
    });
    try http.listen();

    std.log.info("HTTP server listening on http://localhost:3000", .{});
    std.log.info("WebSocket server listening on ws://localhost:3000", .{});
    std.log.info("Terminate with CTRL+C", .{});

    zap.start(.{
        .threads = threads,
        .workers = workers,
    });
}
