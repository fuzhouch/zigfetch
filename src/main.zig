const std = @import("std");
const cmdline = @import("./cmdline.zig");
const builtin = @import("builtin");

pub fn main() !void {
    var alloc: std.mem.Allocator = undefined;
    var dbg = std.heap.DebugAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    if (builtin.mode == .Debug) {
        alloc = dbg.allocator();
    } else {
        alloc = arena.allocator();
    }

    defer {
        arena.deinit();
        const check = dbg.deinit();
        switch (check) {
            .ok => {},
            .leak => {
                std.debug.print("Memory leaks detected!\n", .{});
            },
        }
    }

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const opts = cmdline.init(alloc, args) catch |err| {
        std.debug.print("Error: {}", .{err});
        cmdline.printUsage();
        return;
    };
    defer opts.deinit();

    switch (opts.action) {
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
