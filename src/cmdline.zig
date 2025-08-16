//! Functions to parse command arguments. We intentionally avoid
//! using third-party libraries because I want to ensure zigfetch
//! works without the needs of downloading any dependency.

const std = @import("std");

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

pub fn parse(args: [][:0]u8) !Action {
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h")) {
            return .help;
        } else if (std.mem.eql(u8, arg, "--help")) {
            return .help;
        }
    }
    return .unknown;
}
