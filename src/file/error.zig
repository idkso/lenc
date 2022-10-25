const std = @import("std");
const util = @import("../util.zig");

pub fn err(e: anyerror) noreturn {
    switch (e) {
        .AuthenticationFailed => util.err("authentication failed, please check the keys used"),
        .OutOfMemory => util.err("out of memory, try turning the chunk size down"),
        else => util.err("unexpected error"),
    }
}
