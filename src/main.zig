const std = @import("std");
const args = @import("./args.zig");

pub fn main() !void {
    const action = args.parse(std.os.argv) catch |err| {
        std.debug.print("Error: {}", .{err});
    };

    switch (action) {
        .unknown => {
            const stdout_fd = std.io.getStdOut().writer();
            var bw = std.io.bufferedWriter(stdout_fd);
            const stdout = bw.writer();
            _ = stdout.print("{s}", .{"Unsupported option\n"}) catch unreachable;
            bw.flush() catch unreachable;
        },
        .help => {
            args.printUsage();
            return;
        },
        .save => unreachable,
        .save_exact => unreachable,
    }
}
