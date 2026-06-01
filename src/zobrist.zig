const std = @import("std");
const bitboard = @import("bitboard.zig");

fn splitmix64(state: *u64) u64 {
    state.* +%= 0x9e3779b97f4a7c15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
    return z ^ (z >> 31);
}

fn generateKeys() [12][64]u64 {
    @setEvalBranchQuota(10000);
    var state: u64 = 0xdeadbeefcafe1234;
    var keys: [12][64]u64 = undefined;
    for (0..12) |p| {
        for (0..64) |sq| {
            keys[p][sq] = splitmix64(&state);
        }
    }
    return keys;
}

fn generateCastlingKeys() [16]u64 {
    @setEvalBranchQuota(1000);
    var state: u64 = 0xabcdef0123456789;
    var keys: [16]u64 = undefined;
    for (0..16) |i| {
        keys[i] = splitmix64(&state);
    }
    return keys;
}

fn generateEpKeys() [8]u64 {
    @setEvalBranchQuota(1000);
    var state: u64 = 0x1122334455667788;
    var keys: [8]u64 = undefined;
    for (0..8) |i| {
        keys[i] = splitmix64(&state);
    }
    return keys;
}

pub const PIECE_KEYS: [12][64]u64 = generateKeys();
pub const CASTLING_KEYS: [16]u64 = generateCastlingKeys();
pub const EP_KEYS: [8]u64 = generateEpKeys();
pub const SIDE_KEY: u64 = 0x463d36f9c9b5ef9a;

pub const PieceIndex = struct {
    pub const WP = 0;
    pub const WN = 1;
    pub const WB = 2;
    pub const WR = 3;
    pub const WQ = 4;
    pub const WK = 5;
    pub const BP = 6;
    pub const BN = 7;
    pub const BB = 8;
    pub const BR = 9;
    pub const BQ = 10;
    pub const BK = 11;
};

pub fn computeHash(pos: *const bitboard.Position) u64 {
    var hash: u64 = 0;

    var bb: u64 = undefined;

    bb = pos.white_pawns;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WP][sq]; bb &= bb - 1; }
    bb = pos.white_knights;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WN][sq]; bb &= bb - 1; }
    bb = pos.white_bishops;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WB][sq]; bb &= bb - 1; }
    bb = pos.white_rooks;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WR][sq]; bb &= bb - 1; }
    bb = pos.white_queens;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WQ][sq]; bb &= bb - 1; }
    bb = pos.white_king;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.WK][sq]; bb &= bb - 1; }

    bb = pos.black_pawns;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BP][sq]; bb &= bb - 1; }
    bb = pos.black_knights;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BN][sq]; bb &= bb - 1; }
    bb = pos.black_bishops;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BB][sq]; bb &= bb - 1; }
    bb = pos.black_rooks;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BR][sq]; bb &= bb - 1; }
    bb = pos.black_queens;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BQ][sq]; bb &= bb - 1; }
    bb = pos.black_king;
    while (bb != 0) { const sq = @ctz(bb); hash ^= PIECE_KEYS[PieceIndex.BK][sq]; bb &= bb - 1; }

    hash ^= CASTLING_KEYS[pos.castling];

    if (pos.en_passant_sq) |ep_sq| {
        const file = @intFromEnum(ep_sq) % 8;
        hash ^= EP_KEYS[file];
    }

    if (pos.side_to_move) hash ^= SIDE_KEY;

    return hash;
}
