const std = @import("std");
const clap = @import("clap");
const util = @import("util.zig");

const Args = @This();

alloc: std.mem.Allocator,
cmd: Command = .none,
file: ?[]const u8 = null,
output: ?[]const u8 = null,
pubkey: ?[]const u8 = null,
seckey: ?[]const u8 = null,
csize: ?usize = null,

pub fn deinit(self: *Args) void {
    if (self.file) |x| self.alloc.free(x);
    if (self.output) |x| self.alloc.free(x);
    if (self.pubkey) |x| self.alloc.free(x);
    if (self.seckey) |x| self.alloc.free(x);
}

pub fn format(
    self: Args,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("{s}", .{@tagName(self.cmd)});
    if (self.file) |f| {
        try writer.print(" - [file: {s}]", .{f});
    }
    if (self.output) |f| {
        try writer.print(" - [output: {s}]", .{f});
    }
    if (self.pubkey) |f| {
        try writer.print(" - [pubkey: {s}]", .{f});
    }
    if (self.seckey) |f| {
        try writer.print(" - [seckey: {s}]", .{f});
    }
}

pub fn parse(alloc: std.mem.Allocator) !Args {
    const params = comptime clap.parseParamsComptime(@embedFile("params.txt"));

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = alloc,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var args: Args = .{ .alloc = alloc };

    if (res.args.help) {
        try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
        std.os.exit(0);
    }

    if (res.args.generate) {
        args.cmd = .generate;
    }

    if (res.args.encrypt) |f| {
        args.cmd = .encrypt;
        args.file = try alloc.dupe(u8, f);
    }

    if (res.args.decrypt) |f| {
        args.cmd = .decrypt;
        args.file = try alloc.dupe(u8, f);
    }

    if (res.args.output) |f| {
        args.output = try alloc.dupe(u8, f);
    }

    if (res.args.pubkey) |f| {
        args.pubkey = try alloc.dupe(u8, f);
    }

    if (res.args.seckey) |f| {
        args.seckey = try alloc.dupe(u8, f);
    }

    if (res.args.chunksize) |f| {
        args.csize = try util.parseSize(f);
    }

    return args;
}

pub const Command = enum {
    none,
    generate,
    encrypt,
    decrypt,
};
