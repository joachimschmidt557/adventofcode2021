const Builder = @import("std").build.Builder;

const days = [_][]const u8{
    "01",
    "01_2",
    "02",
    "02_2",
    "03",
    "03_2",
    "04",
    "04_2",
    "05",
    "06",
    "06_2",
    "07",
    "08",
    "08_2",
    "09",
    "09_2",
    "10",
    "10_2",
    "11",
    "11_2",
    "12",
    "12_2",
    "13",
    "13_2",
    "14",
    "14_2",
    "15",
};

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    inline for (days) |day| {
        const exe = b.addExecutable(day, "src/" ++ day ++ ".zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(day, "Run " ++ day);
        run_step.dependOn(&run_cmd.step);

        var tests = b.addTest("src/" ++ day ++ ".zig");
        tests.setBuildMode(mode);

        const test_step = b.step("test" ++ day, "Run tests for day " ++ day);
        test_step.dependOn(&tests.step);
    }
}
