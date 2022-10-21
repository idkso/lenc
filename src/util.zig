const std = @import("std");
const root = @import("root");

const Encryption = @import("context.zig");

pub fn err(msg: []const u8) noreturn {
    std.debug.print("err: {s}\n", .{msg});
    std.debug.print("use the -h flag for cli usage\n", .{});
    std.os.exit(1);
}

pub fn readKey(alloc: std.mem.Allocator, file: []const u8) ![]u8 {
    var cwd = std.fs.cwd();
    var f = try cwd.openFile(file, .{ .mode = .read_only });
    defer f.close();
    var reader = f.reader();
    var read = try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', root.MAX_SIZE) orelse err("empty file??");
    defer alloc.free(read);
    var decoded = try Encryption.decode(alloc, read);
    return decoded;
}

pub fn toStack(text: []const u8, comptime length: usize) [length]u8 {
    return text[0..length].*;
}

pub fn parseSize(raw: []const u8) !usize {
    var buf: [16]u8 = undefined;
    var place: usize = 0;
    for (raw) |c| {
        if (std.ascii.isDigit(c) or c == '.') {
            place += 1;
        } else {
            break;
        }
    }

    var idk = try std.fmt.parseFloat(f64, raw[0..place]);

    while (place < raw.len and raw[place] == ' ') {
        place += 1;
    }

    const x = std.ComptimeStringMap(Unit, .{
        .{ "kb", .KB },
        .{ "kib", .KiB },
        .{ "k", .KiB },
        .{ "mb", .MB },
        .{ "mib", .MiB },
        .{ "m", .MiB },
        .{ "gb", .GB },
        .{ "gib", .GiB },
        .{ "g", .GiB },
        .{ "tb", .TB },
        .{ "tib", .TiB },
        .{ "t", .TiB },
    });

    if (place == raw.len) {
        return @bitCast(usize, @floor(idk));
    }

    var y = std.ascii.lowerString(&buf, raw[place..]);

    if (!x.has(y)) {
        return error.InvalidUnit;
    }

    return @floatToInt(u64, @floor(switch (x.get(y).?) {
        .KB => idk * kilobyte,
        .KiB => idk * kibibyte,
        .MB => idk * megabyte,
        .MiB => idk * mebibyte,
        .GB => idk * gigabyte,
        .GiB => idk * gibibyte,
        .TB => idk * terabyte,
        .TiB => idk * tebibyte,
        else => unreachable,
    }));
}

const kilobyte = 1000;
const megabyte = 1000 * kilobyte;
const gigabyte = 1000 * megabyte;
const terabyte = 1000 * gigabyte;

const kibibyte = 1024;
const mebibyte = 1024 * kibibyte;
const gibibyte = 1024 * mebibyte;
const tebibyte = 1024 * gibibyte;

const Unit = enum(u8) {
    Byte,
    KB,
    KiB,
    MB,
    MiB,
    GB,
    GiB,
    TB,
    TiB,
};
