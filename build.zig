const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const clog = b.addExecutable("clog", "src/main.zig");
    clog.setBuildMode(b.standardReleaseOptions());
    clog.setOutputDir("zig-cache/");
    clog.setMainPkgPath("src/");
    
    b.default_step.dependOn(&clog.step);
    b.installArtifact(clog);

    generateTests(b);
}

fn generateTests(b: *Builder) void {
    const test_files = [_][]const u8 {
        "src/lexer.zig",
    };

    const test_step = b.step("test", "Run all test files");
    for (test_files) |test_file| {
        const item = b.addTest(test_file);
        item.setMainPkgPath("src/");
        test_step.dependOn(&item.step);
    }
}