const std = @import("std");
const cmdline = @import("cmdline.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var cl = try cmdline.init(alloc, args);
    defer cl.deinit();

    switch (cl.action) {
        .none => {
            cmdline.printUsage();
        },
        .help => {
            cmdline.printUsage();
        },
        .fetch => |opts| {
            if (opts.url.len == 0) {
                cmdline.printUsage();
                return;
            }
            std.debug.print("Fetch URL: {s}, Save: {}\n", .{ opts.url, opts.save });
        },
    }
}

test "cmdline parsing" {
    const alloc = std.testing.allocator;

    const arg0 = try alloc.dupeZ(u8, "zf");
    defer alloc.free(arg0);
    const arg1 = try alloc.dupeZ(u8, "fetch");
    defer alloc.free(arg1);
    const arg2 = try alloc.dupeZ(u8, "--save");
    defer alloc.free(arg2);
    const arg3 = try alloc.dupeZ(u8, "https://example.com/file.zip");
    defer alloc.free(arg3);

    var args = [_][:0]u8{ arg0, arg1, arg2, arg3 };

    var cl = try cmdline.init(alloc, &args);
    defer cl.deinit();

    switch (cl.action) {
        .fetch => |opts| {
            try std.testing.expect(opts.save);
            try std.testing.expectEqualStrings("https://example.com/file.zip", opts.url);
        },
        else => try std.testing.expect(false),
    }
}
