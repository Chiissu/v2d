const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const utils = b.createModule(.{ .root_source_file = b.path("src/utils/main.zig") });

    const exe = b.addExecutable(.{
        .name = "v2d",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
        .core = true,
        .sysgpu = true,
        .sysaudio = true,
    });
    exe.root_module.addImport("mach", mach_dep.module("mach"));

    const zigimg_dep = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zigimg", zigimg_dep.module("zigimg"));

    const zigcv_dep = b.dependency("zigcv", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zigcv", zigcv_dep.module("zigcv"));

    const imgui_dep = b.dependency("mach-imgui", .{ .target = target, .optimize = optimize });
    const imgui_module = b.addModule("mach-imgui", .{
        .root_source_file = imgui_dep.path("src/imgui.zig"),
        .imports = &.{
            .{ .name = "mach", .module = mach_dep.module("mach") },
        },
    });
    exe.root_module.addImport("imgui", imgui_module);
    // utils.addImport("imgui", imgui_module);
    exe.linkLibrary(imgui_dep.artifact("imgui"));

    const nfd_dep = b.dependency("nfd", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("nfd", nfd_dep.module("nfd"));
    // utils.addImport("nfd", nfd_dep.module("nfd"));

    // exe.root_module.addImport("$utils", utils);

    exe.linkSystemLibrary("libmediapipe");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
