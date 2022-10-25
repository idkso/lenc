const std = @import("std");
const util = @import("util.zig");

const Args = @import("args.zig");
const File = @import("file.zig");

pub const panic = @import("panic.zig").panic;
pub const log_level = .info;

pub const MAX_SIZE = 1024 * 1024 * 1024 * 512;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var args = try Args.parse(alloc);
    defer args.deinit();
    switch (args.cmd) {
        .generate => try File.generate(alloc),
        .encrypt => try File.encrypt(
            alloc,
            args.seckey orelse util.err("no secret key specified"),
            args.pubkey orelse util.err("no public key specified"),
            args.file orelse util.err("no file specified"),
            args.output,
            args.csize,
        ),
        .decrypt => try File.decrypt(
            alloc,
            args.seckey orelse util.err("no secret key specified"),
            args.pubkey orelse util.err("no public key specified"),
            args.file orelse util.err("no file specified"),
            args.output,
        ),
        .none => util.err("no command specified, use '-h' flag for usage"),
    }
}
