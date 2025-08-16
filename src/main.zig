const std = @import("std");
const cmdline = @import("./cmdline.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const action = cmdline.parse(args) catch |err| {
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
            cmdline.printUsage();
            return;
        },
        .save => unreachable,
        .save_exact => unreachable,
    }
}
