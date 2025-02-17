const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "intensity", .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize, .strip = optimize != .Debug });

    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zap", zap.module("zap"));

    b.installDirectory(.{ .source_dir = b.path("public"), .install_dir = .{ .custom = "public" }, .install_subdir = "" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the server");
    run_step.dependOn(&run_cmd.step);
}
