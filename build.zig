const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const clog = b.addExecutable("clog", "src/main.zig");
    clog.setBuildMode(b.standardReleaseOptions());
    clog.setOutputDir("zig-cache/");
    clog.setMainPkgPath("src/");
    
    b.default_step.dependOn(&clog.step);
    b.installArtifact(clog);
}