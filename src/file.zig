const std = @import("std");
const util = @import("util.zig");

const File = @This();

nonce: []u8,
tag: []u8,
text: []u8,

pub usingnamespace @import("file/decrypt.zig");
pub usingnamespace @import("file/encrypt.zig");
pub usingnamespace @import("file/generate.zig");
