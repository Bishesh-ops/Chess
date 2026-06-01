const std = @import("std");
const bitboard = @import("bitboard.zig");
const attacks = @import("attacks.zig");

const PAWN_VAL:   i32 = 100;
const KNIGHT_VAL: i32 = 320;
const BISHOP_VAL: i32 = 330;
const ROOK_VAL:   i32 = 500;
const QUEEN_VAL:  i32 = 900;

const BISHOP_PAIR_BONUS: i32 = 30;
const MOBILITY_WEIGHT: i32 = 2;

const PAWN_PST = [64]i32{
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0,
};

const KNIGHT_PST = [64]i32{
   -50,-40,-30,-30,-30,-30,-40,-50,
   -40,-20,  0,  0,  0,  0,-20,-40,
   -30,  0, 10, 15, 15, 10,  0,-30,
   -30,  5, 15, 20, 20, 15,  5,-30,
   -30,  0, 15, 20, 20, 15,  0,-30,
   -30,  5, 10, 15, 15, 10,  5,-30,
   -40,-20,  0,  5,  5,  0,-20,-40,
   -50,-40,-30,-30,-30,-30,-40,-50,
};

const BISHOP_PST = [64]i32{
   -20,-10,-10,-10,-10,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5, 10, 10,  5,  0,-10,
   -10,  5,  5, 10, 10,  5,  5,-10,
   -10,  0, 10, 10, 10, 10,  0,-10,
   -10, 10, 10, 10, 10, 10, 10,-10,
   -10,  5,  0,  0,  0,  0,  5,-10,
   -20,-10,-10,-10,-10,-10,-10,-20,
};

const ROOK_PST = [64]i32{
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     0,  0,  0,  5,  5,  0,  0,  0,
};

const QUEEN_PST = [64]i32{
   -20,-10,-10, -5, -5,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5,  5,  5,  5,  0,-10,
    -5,  0,  5,  5,  5,  5,  0, -5,
     0,  0,  5,  5,  5,  5,  0, -5,
   -10,  5,  5,  5,  5,  5,  0,-10,
   -10,  0,  5,  0,  0,  0,  0,-10,
   -20,-10,-10, -5, -5,-10,-10,-20,
};

const KING_PST = [64]i32{
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -20,-30,-30,-40,-40,-30,-30,-20,
   -10,-20,-20,-20,-20,-20,-20,-10,
    20, 20,  0,  0,  0,  0, 20, 20,
    20, 30, 10,  0,  0, 10, 30, 20,
};

fn evaluatePiece(pieces_bb: u64, is_white: bool, material_val: i32, pst: []const i32) i32 {
    var score: i32 = 0;
    var bb = pieces_bb;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        const idx = if (is_white) sq ^ 56 else sq;
        score += material_val + pst[idx];
        bb &= bb - 1;
    }
    return score;
}

fn countBits(bb: u64) i32 {
    return @popCount(bb);
}

fn mobilityScore(pos: *const bitboard.Position) i32 {
    const occupied = pos.getOccupied();
    var white_mob: i32 = 0;
    var black_mob: i32 = 0;

    var bb: u64 = undefined;

    bb = pos.white_knights;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        white_mob += countBits(attacks.getKnightAttacks(sq) & ~pos.getWhitePieces());
        bb &= bb - 1;
    }
    bb = pos.white_bishops;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        white_mob += countBits(attacks.getBishopAttacks(sq, occupied) & ~pos.getWhitePieces());
        bb &= bb - 1;
    }
    bb = pos.white_rooks;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        white_mob += countBits(attacks.getRookAttacks(sq, occupied) & ~pos.getWhitePieces());
        bb &= bb - 1;
    }
    bb = pos.white_queens;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        white_mob += countBits(attacks.getQueenAttacks(sq, occupied) & ~pos.getWhitePieces());
        bb &= bb - 1;
    }

    bb = pos.black_knights;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        black_mob += countBits(attacks.getKnightAttacks(sq) & ~pos.getBlackPieces());
        bb &= bb - 1;
    }
    bb = pos.black_bishops;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        black_mob += countBits(attacks.getBishopAttacks(sq, occupied) & ~pos.getBlackPieces());
        bb &= bb - 1;
    }
    bb = pos.black_rooks;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        black_mob += countBits(attacks.getRookAttacks(sq, occupied) & ~pos.getBlackPieces());
        bb &= bb - 1;
    }
    bb = pos.black_queens;
    while (bb != 0) {
        const sq: u6 = @intCast(@ctz(bb));
        black_mob += countBits(attacks.getQueenAttacks(sq, occupied) & ~pos.getBlackPieces());
        bb &= bb - 1;
    }

    return (white_mob - black_mob) * MOBILITY_WEIGHT;
}

pub fn evaluate(pos: *const bitboard.Position) i32 {
    var score: i32 = 0;

    score += evaluatePiece(pos.white_pawns,   true,  PAWN_VAL,   &PAWN_PST);
    score += evaluatePiece(pos.white_knights, true,  KNIGHT_VAL, &KNIGHT_PST);
    score += evaluatePiece(pos.white_bishops, true,  BISHOP_VAL, &BISHOP_PST);
    score += evaluatePiece(pos.white_rooks,   true,  ROOK_VAL,   &ROOK_PST);
    score += evaluatePiece(pos.white_queens,  true,  QUEEN_VAL,  &QUEEN_PST);
    score += evaluatePiece(pos.white_king,    true,  0,          &KING_PST);

    score -= evaluatePiece(pos.black_pawns,   false, PAWN_VAL,   &PAWN_PST);
    score -= evaluatePiece(pos.black_knights, false, KNIGHT_VAL, &KNIGHT_PST);
    score -= evaluatePiece(pos.black_bishops, false, BISHOP_VAL, &BISHOP_PST);
    score -= evaluatePiece(pos.black_rooks,   false, ROOK_VAL,   &ROOK_PST);
    score -= evaluatePiece(pos.black_queens,  false, QUEEN_VAL,  &QUEEN_PST);
    score -= evaluatePiece(pos.black_king,    false, 0,          &KING_PST);

    if (@popCount(pos.white_bishops) >= 2) score += BISHOP_PAIR_BONUS;
    if (@popCount(pos.black_bishops) >= 2) score -= BISHOP_PAIR_BONUS;

    score += mobilityScore(pos);

    return if (pos.side_to_move) score else -score;
}
