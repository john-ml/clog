const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const clog = b.addExecutable("clog", "src/main.zig");
    clog.setBuildMode(b.standardReleaseOptions());
    clog.setOutputDir("zig-cache/");
    clog.setMainPkgPath("src/");

    switch (builtin.os) {
        .linux => {},
        .windows => clog.setTarget(builtin.arch, builtin.os, builtin.Abi.gnu),
        else => clog.linkSystemLibrary("c"),
    }
    
    b.default_step.dependOn(&clog.step);
    b.installArtifact(clog);

    const run = b.step("run", "Run the executable");
    run.dependOn(&clog.run().step);

    generateTests(b);
}

fn generateTests(b: *Builder) void {
    const test_files = [_][]const u8 {
        "src/heap.zig",
        "src/cache.zig",
        "src/lexer.zig",
    };

    const test_step = b.step("test", "Run all test files");
    for (test_files) |test_file| {
        const item = b.addTest(test_file);
        item.setMainPkgPath("src/");
        test_step.dependOn(&item.step);
    }
}
