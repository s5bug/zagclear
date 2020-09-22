const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const host_target_opt = b.option([]const u8, "target-host", "The CPU architecture, OS, and ABI to build for on the Host");
    const host_target = parse_target_opt(target, host_target_opt);

    const remote_target_opt = b.option([]const u8, "target-remote", "The CPU architecture, OS, and ABI to build for on the Remote");
    const remote_target = parse_target_opt(target, remote_target_opt);

    const host = b.addExecutable("zagclear_host", "src/host.zig");
    host.setTarget(host_target);
    host.setBuildMode(mode);

    host.addIncludeDir("include");

    const target_triple_str = host_target.linuxTriple(b.allocator) catch |err| {
        std.debug.warn("{} error while trying to stringify the target triple", .{err});
        std.os.exit(1);
    };
    const lib_dir = std.fs.path.join(b.allocator, &[_][]const u8{ "lib", target_triple_str }) catch |err| {
        std.debug.warn("{} error while trying to render library path", .{err});
        std.os.exit(1);
    };
    host.addLibPath(lib_dir);

    host.linkLibC();
    host.linkSystemLibrary("usb-1.0");
    host.linkSystemLibrary("cold_clear");

    if (host_target.getOs().tag == .linux) {
        host.linkSystemLibraryPkgConfigOnly("libudev") catch |err| {
            std.debug.warn("{} error while trying to find udev via pkg-config", .{err});
            std.os.exit(1);
        };
    }

    host.install();

    const run_cmd = host.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the Host app");
    run_step.dependOn(&run_cmd.step);

    const remote = b.addStaticLibrary("zagclear_remote", "src/remote.zig");
    remote.setTarget(remote_target);
    remote.setBuildMode(mode);

    remote.linkLibC();

    remote.emit_h = true;
    remote.force_pic = true;
    remote.strip = true;

    remote.install();
}

fn parse_target_opt(default_target: std.zig.CrossTarget, target: ?[]const u8) std.zig.CrossTarget {
    if (target) |triple| {
        var diags: std.zig.CrossTarget.ParseOptions.Diagnostics = .{};
        const selected_target = std.zig.CrossTarget.parse(.{
            .arch_os_abi = triple,
            .diagnostics = &diags,
        }) catch |err| switch (err) {
            error.UnknownCpuModel => {
                std.debug.warn("Unknown CPU: '{}'\nAvailable CPUs for architecture '{}':\n", .{
                    diags.cpu_name.?,
                    @tagName(diags.arch.?),
                });
                for (diags.arch.?.allCpuModels()) |cpu| {
                    std.debug.warn(" {}\n", .{cpu.name});
                }
                std.process.exit(1);
            },
            error.UnknownCpuFeature => {
                std.debug.warn(
                    \\Unknown CPU feature: '{}'
                    \\Available CPU features for architecture '{}':
                    \\
                , .{
                    diags.unknown_feature_name,
                    @tagName(diags.arch.?),
                });
                for (diags.arch.?.allFeaturesList()) |feature| {
                    std.debug.warn(" {}: {}\n", .{ feature.name, feature.description });
                }
                std.process.exit(1);
            },
            error.UnknownOperatingSystem => {
                std.debug.warn(
                    \\Unknown OS: '{}'
                    \\Available operating systems:
                    \\
                , .{diags.os_name});
                inline for (std.meta.fields(std.Target.Os.Tag)) |field| {
                    std.debug.warn(" {}\n", .{field.name});
                }
                std.process.exit(1);
            },
            else => |e| {
                std.debug.warn("Unable to parse target '{}': {}\n", .{ triple, @errorName(e) });
                std.process.exit(1);
            },
        };
        return selected_target;
    } else {
        return default_target;
    }
}
