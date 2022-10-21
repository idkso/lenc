const std = @import("std");
const builtin = @import("builtin");

pub const panic = switch (builtin.mode) {
    .Debug, .ReleaseSafe => std.builtin.default_panic,
    .ReleaseFast, .ReleaseSmall => panicSmall,
};

pub fn panicSmall(msg: []const u8, trace: ?*const std.builtin.StackTrace, first_trace_addr: ?usize) noreturn {
    std.debug.print("{s}", .{msg});

    if (first_trace_addr) |f| {
        std.debug.print(": {d}\n", .{f});
    }
    if (trace) |t| {
        std.debug.print("{}\n", .{t});
    }

    std.debug.print("\n", .{});

    std.os.abort();
}
