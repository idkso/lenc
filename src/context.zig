const std = @import("std");

kp: X25519.KeyPair,

const X25519 = std.crypto.dh.X25519;
const Poly1305 = std.crypto.onetimeauth.Poly1305;
const XChaCha20Poly1305 = std.crypto.aead.chacha_poly.XChaCha20Poly1305;

const Context = @This();

const b64 = std.base64.standard;
pub const ec = b64.Encoder;
pub const dc = b64.Decoder;

pub fn new() !Context {
    return .{ .kp = try X25519.KeyPair.create(null) };
}

pub fn from(private: [32]u8) !Context {
    var enc: Context = undefined;
    enc.kp.secret_key = private;
    enc.kp.public_key = try X25519.recoverPublicKey(private);
    return enc;
}

pub const Shared = struct {
    text: []u8,
    tag: [XChaCha20Poly1305.tag_length]u8,
    nonce: [XChaCha20Poly1305.nonce_length]u8,
};

pub const Encryption = struct {
    nonce: [XChaCha20Poly1305.nonce_length]u8,
    tag: [XChaCha20Poly1305.tag_length]u8,
};

pub fn encrypt(
    self: ?*Context,
    alloc: std.mem.Allocator,
    pubkey: ?[32]u8,
    shared: ?[32]u8,
    text: []const u8,
    ad: ?[]const u8,
) !Shared {
    var sh = shared orelse try X25519.scalarmult(self.?.kp.secret_key, pubkey orelse unreachable);

    var buf = try alloc.alloc(u8, text.len);
    var nonce: [XChaCha20Poly1305.nonce_length]u8 = undefined;
    std.crypto.random.bytes(&nonce);
    var tag: [XChaCha20Poly1305.tag_length]u8 = undefined;
    XChaCha20Poly1305.encrypt(buf, &tag, text, ad orelse "default", nonce, sh);
    return .{
        .text = buf,
        .tag = tag,
        .nonce = nonce,
    };
}

pub fn decrypt(
    self: ?*Context,
    alloc: std.mem.Allocator,
    tag: [XChaCha20Poly1305.tag_length]u8,
    nonce: [XChaCha20Poly1305.nonce_length]u8,
    pubkey: ?[32]u8,
    shared: ?[32]u8,
    text: []const u8,
    ad: ?[]const u8,
) ![]u8 {
    var sh = shared orelse try X25519.scalarmult(self.?.kp.secret_key, pubkey orelse unreachable);
    var buf = try alloc.alloc(u8, text.len);
    try XChaCha20Poly1305.decrypt(buf, text, tag, ad orelse "default", nonce, sh);
    return buf;
}

pub fn encode(alloc: std.mem.Allocator, text: []const u8) ![]u8 {
    var len = ec.calcSize(text.len);
    var buf = try alloc.alloc(u8, len);
    _ = ec.encode(buf, text);
    return buf;
}

pub fn decode(alloc: std.mem.Allocator, text: []const u8) ![]u8 {
    var len = try dc.calcSizeForSlice(text);
    var buf = try alloc.alloc(u8, len);
    _ = try dc.decode(buf, text);
    return buf;
}
