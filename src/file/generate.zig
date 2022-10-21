const std = @import("std");
const util = @import("../util.zig");

const Context = @import("../context.zig");

pub fn generate(alloc: std.mem.Allocator) !void {
    var ec = try Context.new();
    var cwd = std.fs.cwd();

    var f = try cwd.createFile("key.sec", .{});
    var lol = try Context.encode(alloc, &ec.kp.secret_key);
    _ = try f.writeAll(lol);
    f.close();
    alloc.free(lol);
    std.log.info("wrote secret key to key.sec", .{});

    f = try cwd.createFile("key.pub", .{});
    lol = try Context.encode(alloc, &ec.kp.public_key);
    _ = try f.writeAll(lol);
    f.close();
    alloc.free(lol);
    std.log.info("wrote public key to key.pub", .{});
}
