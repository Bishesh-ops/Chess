const std = @import("std");
const bitboard = @import("bitboard.zig");

const PAWN_VAL: i32 = 100;
const KNIGHT_VAL: i32 = 320;
const BISHOP_VAL: i32 = 330;
const ROOK_VAL: i32 = 500;
const QUEEN_VAL: i32 = 900;

const PAWN_PST = [64]i32{
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
};

const KNIGHT_PST = [64]i32{
   -50,-40,-30,-30,-30,-30,-40,-50,
   -40,-20,  0,  0,  0,  0,-20,-40,
   -30,  0, 10, 15, 15, 10,  0,-30,
   -30,  5, 15, 20, 20, 15,  5,-30,
   -30,  0, 15, 20, 20, 15,  0,-30,
   -30,  5, 10, 15, 15, 10,  5,-30,
   -40,-20,  0,  5,  5,  0,-20,-40,
   -50,-40,-30,-30,-30,-30,-40,-50
};

const BISHOP_PST = [64]i32{
   -20,-10,-10,-10,-10,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5, 10, 10,  5,  0,-10,
   -10,  5,  5, 10, 10,  5,  5,-10,
   -10,  0, 10, 10, 10, 10,  0,-10,
   -10, 10, 10, 10, 10, 10, 10,-10,
   -10,  5,  0,  0,  0,  0,  5,-10,
   -20,-10,-10,-10,-10,-10,-10,-20
};

const ROOK_PST = [64]i32{
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     0,  0,  0,  5,  5,  0,  0,  0
};

const QUEEN_PST = [64]i32{
   -20,-10,-10, -5, -5,-10,-10,-20,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -10,  0,  5,  5,  5,  5,  0,-10,
    -5,  0,  5,  5,  5,  5,  0, -5,
     0,  0,  5,  5,  5,  5,  0, -5,
   -10,  5,  5,  5,  5,  5,  0,-10,
   -10,  0,  5,  0,  0,  0,  0,-10,
   -20,-10,-10, -5, -5,-10,-10,-20
};

const KING_PST = [64]i32{
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -20,-30,-30,-40,-40,-30,-30,-20,
   -10,-20,-20,-20,-20,-20,-20,-10,
    20, 20,  0,  0,  0,  0, 20, 20,
    20, 30, 10,  0,  0, 10, 30, 20
};

fn evaluatePiece(pieces_bb: u64, is_white: bool, material_val: i32, pst: []const i32) i32 {
    var score: i32 = 0;
    var pieces = pieces_bb;
    
    while (pieces != 0) {
        const sq: u6 = @intCast(@ctz(pieces));
        const table_idx = if (is_white) sq ^ 56 else sq;
        
        score += material_val + pst[table_idx];
        pieces &= pieces - 1;
    }
    return score;
}

pub fn evaluate(pos: *const bitboard.Position) i32 {
    var score: i32 = 0;

    score += evaluatePiece(pos.white_pawns, true, PAWN_VAL, &PAWN_PST);
    score += evaluatePiece(pos.white_knights, true, KNIGHT_VAL, &KNIGHT_PST);
    score += evaluatePiece(pos.white_bishops, true, BISHOP_VAL, &BISHOP_PST);
    score += evaluatePiece(pos.white_rooks, true, ROOK_VAL, &ROOK_PST);
    score += evaluatePiece(pos.white_queens, true, QUEEN_VAL, &QUEEN_PST);
    score += evaluatePiece(pos.white_king, true, 0, &KING_PST); // King material is irrelevant

    score -= evaluatePiece(pos.black_pawns, false, PAWN_VAL, &PAWN_PST);
    score -= evaluatePiece(pos.black_knights, false, KNIGHT_VAL, &KNIGHT_PST);
    score -= evaluatePiece(pos.black_bishops, false, BISHOP_VAL, &BISHOP_PST);
    score -= evaluatePiece(pos.black_rooks, false, ROOK_VAL, &ROOK_PST);
    score -= evaluatePiece(pos.black_queens, false, QUEEN_VAL, &QUEEN_PST);
    score -= evaluatePiece(pos.black_king, false, 0, &KING_PST);

    // Negamax requirement: return score from the perspective of the side to move
    return if (pos.side_to_move) score else -score;
}
