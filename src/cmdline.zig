//! Functions to parse command arguments. We intentionally avoid
//! using third-party libraries because I want to ensure zigfetch
//! works without the needs of downloading any dependency.

const std = @import("std");
const builtin = @import("builtin");

pub fn printUsage() void {
    const usage =
        \\Usage: zf fetch [options] <url>
        \\
        \\Options:
        \\ -h, --help      Print this help and exit
        \\ --save          Add the fetched package to build.zig.zon
        \\
    ;
    _ = std.debug.print("{s}", .{usage});
}

pub const FetchOptions = struct {
    save: bool = false,
    url: []const u8 = "",
};

pub const ActionTag = enum {
    none,
    help,
    fetch,
};

pub const Action = union(ActionTag) {
    none: void,
    help: void,
    fetch: FetchOptions,
};

pub const Cmdline = struct {
    alloc: std.mem.Allocator,
    action: Action,
    global_cache_dir: ?[]const u8,
    args: [][:0]u8,

    pub fn deinit(self: Cmdline) void {
        if (self.global_cache_dir) |cache_dir| {
            self.alloc.free(cache_dir);
        }
    }
};

const ParseError = error{
    InvalidArgument,
    MissingArgument,
};

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
        .action = .none,
        .global_cache_dir = null,
        .args = args,
    };

    // Attempt to resolve global cache dir.
    cmdline.global_cache_dir = try resolveGlobalCacheDir(alloc);

    if (args.len < 2) {
        return cmdline;
    }

    const cmd = args[1];
    if (std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help")) {
        cmdline.action = .help;
        return cmdline;
    }

    if (std.mem.eql(u8, cmd, "fetch")) {
        var opts = FetchOptions{};
        var i: usize = 2;
        var url_found = false;

        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                cmdline.action = .help;
                return cmdline;
            } else if (std.mem.eql(u8, arg, "--save")) {
                opts.save = true;
            } else if (std.mem.startsWith(u8, arg, "-")) {
                // Unknown option, for now we treat it as invalid if strict,
                // but for simplicity we might just ignore or print error?
                // Let's print error in main or just ignore for now?
                // The spec is simple.
            } else {
                if (!url_found) {
                    opts.url = arg;
                    url_found = true;
                }
            }
        }

        if (url_found) {
            cmdline.action = .{ .fetch = opts };
        } else {
            // Fetch without URL?
            // Maybe user just typed `zf fetch`.
            // We can let action be none or help or handle in main.
            // Let's set it to fetch with empty url, main should check.
            cmdline.action = .{ .fetch = opts };
        }
    }

    return cmdline;
}
