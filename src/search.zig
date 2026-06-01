const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const attacks = @import("attacks.zig");
const evaluate = @import("evaluate.zig");

const MATE_SCORE: i32 = 30000;
const INFINITY: i32 = 50000;

fn quiescence(pos: *bitboard.Position, alpha_in: i32, beta_in: i32) i32 {
    var alpha = alpha_in;
    const beta = beta_in;

    const stand_pat = evaluate.evaluate(pos);
    
    if (stand_pat >= beta) {
        return beta;
    }
    if (alpha < stand_pat) {
        alpha = stand_pat;
    }

    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    for (list.moves[0..list.count]) |move| {
        if (move.flags != @intFromEnum(movegen.MoveFlag.capture) and 
            move.flags != @intFromEnum(movegen.MoveFlag.ep_capture)) {
            continue;
        }

        var next_pos = pos.*;
        if (!movegen.makeMove(&next_pos, move)) continue;

        const score = -quiescence(&next_pos, -beta, -alpha);

        if (score >= beta) {
            return beta;
        }
        if (score > alpha) {
            alpha = score;
        }
    }

    return alpha;
}

fn negamax(pos: *bitboard.Position, depth: u8, alpha_in: i32, beta_in: i32) i32 {
    var alpha = alpha_in;
    const beta = beta_in;

    if (depth == 0) {
        return quiescence(pos, alpha, beta);
    }

    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    var legal_moves: u32 = 0;
    var max_score: i32 = -INFINITY;

    for (list.moves[0..list.count]) |move| {
        var next_pos = pos.*;
        if (!movegen.makeMove(&next_pos, move)) continue;
        
        legal_moves += 1;

        const score = -negamax(&next_pos, depth - 1, -beta, -alpha);

        if (score > max_score) {
            max_score = score;
        }
        
        if (score > alpha) {
            alpha = score;
        }
        if (alpha >= beta) {
            break; 
        }
    }

    if (legal_moves == 0) {
        const is_white = pos.side_to_move;
        const king_sq: u6 = @intCast(@ctz(if (is_white) pos.white_king else pos.black_king));
        const in_check = attacks.isSquareAttacked(pos, king_sq, !is_white);
        
        if (in_check) {
            return -MATE_SCORE + @as(i32, depth); 
        } else {
            return 0; 
        }
    }

    return max_score;
}

pub fn findBestMove(pos: *bitboard.Position, depth: u8) movegen.Move {
    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    var best_move: movegen.Move = list.moves[0]; 
    var best_score: i32 = -INFINITY;
    var alpha: i32 = -INFINITY;
    const beta: i32 = INFINITY;

    for (list.moves[0..list.count]) |move| {
        var next_pos = pos.*;
        if (!movegen.makeMove(&next_pos, move)) continue;

        const score = -negamax(&next_pos, depth - 1, -beta, -alpha);

        if (score > best_score) {
            best_score = score;
            best_move = move;
        }
        
        if (score > alpha) {
            alpha = score;
        }
    }

    return best_move;
}
