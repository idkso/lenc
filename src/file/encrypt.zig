const std = @import("std");
const util = @import("../util.zig");
const err = @import("error.zig");

const Context = @import("../context.zig");

const File = @import("../file.zig");

pub fn encrypt(
    alloc: std.mem.Allocator,
    seckey: []const u8,
    pubkey: []const u8,
    file: []const u8,
    output: ?[]const u8,
    csize: ?usize,
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
    var out = try cwd.createFile(output orelse "out.lenc", .{});
    defer out.close();

    var chunksize = csize orelse comptime util.parseSize("1M") catch unreachable;

    while (try f.getPos() < try f.getEndPos()) {
        try write(alloc, shared, &f, &out, chunksize);
    }
}

pub fn write(alloc: std.mem.Allocator, shared: [32]u8, file: *std.fs.File, output: *std.fs.File, csize: usize) !void {
    var buf = try alloc.alloc(u8, csize);
    var reader = file.reader();
    var len = try reader.read(buf);
    var text = buf[0..len];

    var res = Context.encrypt(null, alloc, null, shared, text, null) catch |e| err.err(e);
    alloc.free(buf);

    var nonce = try Context.encode(alloc, &res.nonce);
    defer alloc.free(nonce);

    var tag = try Context.encode(alloc, &res.tag);
    defer alloc.free(tag);

    var txt = try Context.encode(alloc, res.text);
    defer alloc.free(txt);
    alloc.free(res.text);

    var fuck = try alloc.alloc(u8, nonce.len + tag.len + txt.len + 2);
    defer alloc.free(fuck);

    var fbs = std.io.fixedBufferStream(fuck);
    var w = fbs.writer();

    _ = try w.writeAll(nonce);
    _ = try w.writeAll("\n");
    _ = try w.writeAll(tag);
    _ = try w.writeAll("\n");
    _ = try w.writeAll(txt);

    buf = try alloc.alloc(u8, Context.ec.calcSize(192));
    defer alloc.free(buf);
    var i: usize = 0;
    while (i < fuck.len) : (i += 192) {
        len = if (fuck.len > i + 192) i + 192 else fuck.len;
        var out = Context.ec.encode(buf, fuck[i..len]);
        _ = try output.writeAll(out);
    }
    _ = try output.writeAll("\n");
}
