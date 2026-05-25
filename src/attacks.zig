const std = @import("std");
const bitboard = @import("bitboard.zig");
const Bitboard = bitboard.Bitboard;

const NOT_A_FILE: u64 = ~@as(u64, 0x0101010101010101);
const NOT_H_FILE: u64 = ~@as(u64, 0x8080808080808080);

fn initRay(comptime dx: i8, comptime dy: i8) [64]Bitboard {
    var rays: [64]Bitboard = undefined;

    for (0..64) |sq| {
        var ray: Bitboard = 0;

        var x: i8 = @intCast(sq % 8);
        var y: i8 = @intCast(sq / 8);

        while (true) {
            x += dx;
            y += dy;

            if (x < 0 or x > 7 or y < 0 or y > 7) break;

            const target_sq = @as(u6, @intCast(y * 8 + x));
            ray |= (@as(u64, 1) << target_sq);
        }
        rays[sq] = ray;
    }

    return rays;
}

pub const ray_N = initRay(0, 1); // North
pub const ray_S = initRay(0, -1); // South
pub const ray_E = initRay(1, 0); // East
pub const ray_W = initRay(-1, 0); // West
pub const ray_NE = initRay(1, 1); // NorthEast
pub const ray_NW = initRay(-1, 1); // NorthWest
pub const ray_SE = initRay(1, -1); // SouthEast
pub const ray_SW = initRay(-1, -1); // SouthWest

fn initKnightAttacks() [64]Bitboard {
    var attacks: [64]Bitboard = undefined;

    const dx = [_]i8{ 1, 2, 2, 1, -1, -2, -2, -1 };
    const dy = [_]i8{ 2, 1, -1, -2, -2, -1, 1, 2 };

    for (0..64) |sq| {
        var mask: Bitboard = 0;
        const x: i8 = @intCast(sq % 8);
        const y: i8 = @intCast(sq / 8);

        for (0..8) |i| {
            const nx = x + dx[i];
            const ny = y + dy[i];

            if (nx >= 0 and nx < 8 and ny >= 0 and ny < 8) {
                const target_sq = @as(u6, @intCast(ny * 8 + nx));
                mask |= (@as(u64, 1) << target_sq);
            }
        }
        attacks[sq] = mask;
    }
    return attacks;
}

fn initKingAttacks() [64]Bitboard {
    var attacks: [64]Bitboard = undefined;

    const dx = [_]i8{ 0, 1, 1, 1, 0, -1, -1, -1 };
    const dy = [_]i8{ 1, 1, 0, -1, -1, -1, 0, 1 };

    for (0..64) |sq| {
        var mask: Bitboard = 0;
        const x: i8 = @intCast(sq % 8);
        const y: i8 = @intCast(sq / 8);

        for (0..8) |i| {
            const nx = x + dx[i];
            const ny = y + dy[i];

            if (nx >= 0 and nx < 8 and ny >= 0 and ny < 8) {
                const target_sq = @as(u6, @intCast(ny * 8 + nx));
                mask |= (@as(u64, 1) << target_sq);
            }
        }
        attacks[sq] = mask;
    }
    return attacks;
}

pub const KNIGHT_ATTACKS = initKnightAttacks();
pub const KING_ATTACKS = initKingAttacks();

pub fn getRookAttacks(sq: u6, occupied: Bitboard) Bitboard {
    var attacks: Bitboard = 0;
    var blockers: Bitboard = undefined;

    // North
    blockers = ray_N[sq] & occupied;
    if (blockers == 0) attacks |= ray_N[sq] else attacks |= ray_N[sq] ^ ray_N[@ctz(blockers)];

    // South
    blockers = ray_S[sq] & occupied;
    if (blockers == 0) attacks |= ray_S[sq] else attacks |= ray_S[sq] ^ ray_S[@as(u6, @intCast(63 - @clz(blockers)))];

    // East
    blockers = ray_E[sq] & occupied;
    if (blockers == 0) attacks |= ray_E[sq] else attacks |= ray_E[sq] ^ ray_E[@ctz(blockers)];

    // West
    blockers = ray_W[sq] & occupied;
    if (blockers == 0) attacks |= ray_W[sq] else attacks |= ray_W[sq] ^ ray_W[@as(u6, @intCast(63 - @clz(blockers)))];

    return attacks;
}

pub fn getBishopAttacks(sq: u6, occupied: Bitboard) Bitboard {
    var attacks: Bitboard = 0;
    var blockers: Bitboard = undefined;

    // NorthEast
    blockers = ray_NE[sq] & occupied;
    if (blockers == 0) attacks |= ray_NE[sq] else attacks |= ray_NE[sq] ^ ray_NE[@ctz(blockers)];

    // NorthWest
    blockers = ray_NW[sq] & occupied;
    if (blockers == 0) attacks |= ray_NW[sq] else attacks |= ray_NW[sq] ^ ray_NW[@ctz(blockers)];

    // SouthEast
    blockers = ray_SE[sq] & occupied;
    if (blockers == 0) attacks |= ray_SE[sq] else attacks |= ray_SE[sq] ^ ray_SE[@as(u6, @intCast(63 - @clz(blockers)))];

    // SouthWest
    blockers = ray_SW[sq] & occupied;
    if (blockers == 0) attacks |= ray_SW[sq] else attacks |= ray_SW[sq] ^ ray_SW[@as(u6, @intCast(63 - @clz(blockers)))];

    return attacks;
}

pub fn getQueenAttacks(sq: u6, occupied: Bitboard) Bitboard {
    return getRookAttacks(sq, occupied) | getBishopAttacks(sq, occupied);
}

pub fn getKnightAttacks(sq: u6) Bitboard {
    return KNIGHT_ATTACKS[sq];
}

pub fn getKingAttacks(sq: u6) Bitboard {
    return KING_ATTACKS[sq];
}
