//! Functions to parse command arguments. We intentionally avoid
//! using third-party libraries because I want to ensure zigfetch
//! works without the needs of downloading any dependency.

const std = @import("std");
const builtin = @import("builtin");

pub fn printUsage() void {
    const usage =
        \\This command mimic behavior of zig fetch command for 0.14.0.
        \\
        \\Usage: zf [options] <url>
        \\Usage: zf [options] <path>
        \\
        \\    Copy a package to one of the following:
        \\    <url> must point to one of the following:
        \\    - A git+http / git+https server for the package
        \\    - A tarball file (with or without compression)
        \\      containing package source
        \\    - A git bundle file containing package source
        \\Examples:
        \\
        \\zigfetch --save git+https://example.com/andrewk/fun-example-tool.git
        \\zigfetch --save https://example.com/andrewk/fun-example-tool/archive/refs/heads/master.tar.gz
        \\
        \\Options:
        \\ -h, --help                 Print this help and exit
        \\ --global-cache-dir [path]  Override path to global Zig directory
        \\ --debug-hash               Print verbose hash information to stdout
        \\ --save                     Add the fetched package to build.zig.zon
        \\ --save=[name]              Add the fetched package to build.zig.zon as name
        \\ --save-exact               Add the fetched package to build.zig.zon, storing the URL verbatim
        \\ --save-exact=[name]        Add the fetched package to build.zig.zon as name, storing the URL verbatim
        \\
        \\ZF specific options:
        \\ --git-path                 Specify git command line, Default: `git'
        \\
    ;
    const stdout_fd = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_fd);
    const stdout = bw.writer();
    _ = stdout.print("{s}", .{usage}) catch unreachable;
    bw.flush() catch unreachable;
}

const Command = enum {
    unknown,
    help,
    save,
    save_exact,
};

const Action = union(Command) {
    unknown: void,
    help: void,
    save: ?[]u8,
    save_exact: ?[]u8,
};

const Cmdline = struct {
    alloc: std.mem.Allocator,
    action: Action,
    global_cache_dir: ?[]const u8,
    git_path: ?[]const u8,

    pub fn deinit(cmdline: Cmdline) void {
        if (cmdline.global_cache_dir) |cache_dir| {
            cmdline.alloc.free(cache_dir);
        }
    }
};

const ParseError = error{
    InvalidArgument,
    MissingArgument,
};

const default_git_path: []const u8 = "git";

// This function is copied from standard Zig implementation.
// https://github.com/ziglang/zig/blob/master/src/introspect.zig.
fn resolveGlobalCacheDir(alloc: std.mem.Allocator) ![]u8 {
    if (builtin.os.tag == .wasi) {
        @compileError("On WASI the global cache dir is unsupported");
    }

    if (try std.zig.EnvVar.ZIG_GLOBAL_CACHE_DIR.get(alloc)) |value| {
        return value;
    }
    const appname = "zig";

    if (builtin.os.tag != .windows) {
        if (std.zig.EnvVar.XDG_CACHE_HOME.getPosix()) |cache_root| {
            if (cache_root.len > 0) {
                return try std.fs.path.join(alloc, &.{ cache_root, appname });
            }
        }
        if (std.zig.EnvVar.HOME.getPosix()) |home| {
            return try std.fs.path.join(alloc, &.{ home, ".cache", appname });
        }
    }
    return std.fs.getAppDataDir(alloc, appname);
}

pub fn init(alloc: std.mem.Allocator, args: [][:0]u8) !Cmdline {
    var cmdline = Cmdline{
        .alloc = alloc,
        .action = .unknown,
        .global_cache_dir = null,
        .git_path = null,
    };

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h")) {
            cmdline.action = .help;
        } else if (std.mem.eql(u8, arg, "--help")) {
            cmdline.action = .help;
        } else if (std.mem.startsWith(u8, arg, "--global-cache-dir=")) {
            cmdline.global_cache_dir = arg["--global-cache-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--git-path=")) {
            cmdline.git_path = arg["--git-path=".len..];
        }
    }

    // If user does not specify cache dir or git path, fall
    // back to default values.
    if (cmdline.global_cache_dir == null) {
        cmdline.global_cache_dir = try resolveGlobalCacheDir(alloc);
    }
    cmdline.git_path = cmdline.git_path orelse default_git_path;
    return cmdline;
}
