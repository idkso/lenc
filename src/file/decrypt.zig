const std = @import("std");
const util = @import("../util.zig");

const Context = @import("../context.zig");

const File = @import("../file.zig");

pub fn decrypt(
    alloc: std.mem.Allocator,
    seckey: []const u8,
    pubkey: []const u8,
    file: []const u8,
    output: ?[]const u8,
) !void {
    var decoded = try util.readKey(alloc, seckey);
    defer alloc.free(decoded);

    var ec = try Context.from(decoded[0..32].*);

    var pk = try util.readKey(alloc, pubkey);
    defer alloc.free(pk);

    var shared = try std.crypto.dh.X25519.scalarmult(ec.kp.secret_key, util.toStack(pk, 32));

    var cwd = std.fs.cwd();

    var f = try cwd.openFile(file, .{ .mode = .read_only });
    defer f.close();
    var out: std.fs.File = if (output) |o| try cwd.createFile(o, .{}) else std.io.getStdOut();
    defer if (output) |_| out.close();

    while (try f.getPos() < try f.getEndPos()) {
        try read(alloc, shared, &f, &out);
    }
}

pub fn untilNewline(slice: []const u8) usize {
    var i: usize = 0;
    while (i < slice.len and slice[i] != '\n') : (i += 1) {
        std.debug.print("0 {d} {c}\n", .{ i, slice[i] });
    }
    return i;
}

pub fn read(alloc: std.mem.Allocator, shared: [32]u8, file: *std.fs.File, output: *std.fs.File) !void {
    var reader = file.reader();
    var text = try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', comptime util.parseSize("5G") catch unreachable) orelse util.err("what the fuck");

    var txt = try Context.decode(alloc, text);
    defer alloc.free(txt);
    alloc.free(text);

    var noncelen = Context.ec.calcSize(24);
    var taglen = Context.ec.calcSize(16);

    var nonce = try Context.decode(alloc, txt[0..noncelen]);
    defer alloc.free(nonce);
    var tag = try Context.decode(alloc, txt[noncelen + 1 .. noncelen + taglen + 1]);
    defer alloc.free(tag);
    text = try Context.decode(alloc, txt[noncelen + taglen + 2 ..]);
    defer alloc.free(text);

    var out = try Context.decrypt(null, alloc, util.toStack(tag, 16), util.toStack(nonce, 24), null, shared, text, null);
    defer alloc.free(out);

    _ = try output.writeAll(out);
}
