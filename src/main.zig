const builtin = @import("builtin");
const std = @import("std");
const zap = @import("zap");

const codes = @import("./codes.zig");
const global = @import("./global.zig");
const utility = @import("./utility.zig");

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

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var buffer: [20]u8 = undefined;
    var username: []const u8 = undefined;

    while (true) {
        try stdout.print("Pick your username to join the chat room as: ", .{});

        const readData = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |e| switch (e) {
            error.StreamTooLong => {
                // Clear the remaining input
                _ = try stdin.skipUntilDelimiterOrEof('\n');
                try stdout.print("The username's length has to be within the range of 3 >= x <= 20!\n", .{});
                continue;
            },
            else => {
                try stdout.print("oops, error reading stdin: {}\n", .{e});
                return e;
            },
        };

        if (readData) |input| {
            utility.validateUsername(input) catch |err| {
                switch (err) {
                    error.InvalidCharacters => {
                        try stdout.print("The username is not alphanumeric! [A-Z][a-z][0-9]\n", .{});
                        continue;
                    },
                    error.InvalidLength => {
                        try stdout.print("The username's length has to be within the range of 3 >= x <= 20!\n", .{});
                        continue;
                    },
                }
            };
            username = input;
            break;
        } else {
            try stdout.print("No input received. Please try again.\n", .{});
            continue;
        }
    }

    const join_code = try codes.JoinCode.init(allocator, username);
    try state.join_codes.append(join_code);

    const context_manager = global.initContextManager(allocator);
    defer context_manager.deinit();

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
        .on_upgrade = @import("./listener/upgrade/public.zig").on_upgrade,
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
    std.log.info("Welcome, {s}, use this join code to enter the GC (including the \"{s}|\" portion):\n{s}", .{ username, username, join_code.code });

    zap.start(.{
        .threads = threads,
        .workers = workers,
    });
}
