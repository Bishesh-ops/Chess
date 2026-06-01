const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const attacks = @import("attacks.zig");
const evaluate = @import("evaluate.zig");
const tt = @import("tt.zig");
const zobrist = @import("zobrist.zig");

pub const MATE_SCORE: i32 = 30000;
const INFINITY: i32 = 50000;
const MAX_DEPTH: usize = 64;
const MAX_KILLERS: usize = 2;

const MVV_LVA: [6][6]i32 = .{
    .{ 105, 104, 103, 102, 101, 100 }, // victim Pawn
    .{ 205, 204, 203, 202, 201, 200 }, // victim Knight
    .{ 305, 304, 303, 302, 301, 300 }, // victim Bishop
    .{ 405, 404, 403, 402, 401, 400 }, // victim Rook
    .{ 505, 504, 503, 502, 501, 500 }, // victim Queen
    .{   0,   0,   0,   0,   0,   0 }, // victim King (shouldn't happen)
};

pub const SearchState = struct {
    table: tt.TranspositionTable = .{},
    killers: [MAX_DEPTH][MAX_KILLERS]movegen.Move = [_][MAX_KILLERS]movegen.Move{
        [_]movegen.Move{.{ .source = 0, .target = 0, .flags = 0 }} ** MAX_KILLERS
    } ** MAX_DEPTH,
    nodes: u64 = 0,

    pub fn init() SearchState {
        return .{};
    }
};

fn pieceTypeAt(pos: *const bitboard.Position, sq: u6) ?u3 {
    const mask = @as(u64, 1) << sq;
    if ((pos.white_pawns   | pos.black_pawns)   & mask != 0) return 0;
    if ((pos.white_knights | pos.black_knights) & mask != 0) return 1;
    if ((pos.white_bishops | pos.black_bishops) & mask != 0) return 2;
    if ((pos.white_rooks   | pos.black_rooks)   & mask != 0) return 3;
    if ((pos.white_queens  | pos.black_queens)  & mask != 0) return 4;
    if ((pos.white_king    | pos.black_king)    & mask != 0) return 5;
    return null;
}

fn scoreMoveForOrdering(pos: *const bitboard.Position, move: movegen.Move, ply: usize, state: *const SearchState, tt_move: ?movegen.Move) i32 {
    if (tt_move) |ttm| {
        if (move.source == ttm.source and move.target == ttm.target and move.flags == ttm.flags) {
            return 20000;
        }
    }

    const is_capture = move.flags == @intFromEnum(movegen.MoveFlag.capture) or
                       move.flags == @intFromEnum(movegen.MoveFlag.ep_capture);
    const is_promo   = move.flags >= @intFromEnum(movegen.MoveFlag.promotion_knight);

    if (is_promo) return 10000 + @as(i32, move.flags);

    if (is_capture) {
        const victim   = pieceTypeAt(pos, move.target) orelse 0;
        const attacker = pieceTypeAt(pos, move.source) orelse 0;
        return MVV_LVA[victim][attacker];
    }

    for (state.killers[ply]) |killer| {
        if (killer.source == move.source and killer.target == move.target) {
            return 9000;
        }
    }

    return 0;
}

fn sortMoves(pos: *const bitboard.Position, list: *movegen.MoveList, ply: usize, state: *const SearchState, tt_move: ?movegen.Move) void {
    const count = list.count;
    var scores: [movegen.MAX_POSITION_MOVES]i32 = undefined;
    for (list.moves[0..count], 0..) |move, i| {
        scores[i] = scoreMoveForOrdering(pos, move, ply, state, tt_move);
    }
    var i: usize = 1;
    while (i < count) : (i += 1) {
        const key_move  = list.moves[i];
        const key_score = scores[i];
        var j: usize = i;
        while (j > 0 and scores[j - 1] < key_score) : (j -= 1) {
            list.moves[j] = list.moves[j - 1];
            scores[j]     = scores[j - 1];
        }
        list.moves[j] = key_move;
        scores[j]     = key_score;
    }
}

fn storeKiller(state: *SearchState, move: movegen.Move, ply: usize) void {
    if (state.killers[ply][0].source != move.source or state.killers[ply][0].target != move.target) {
        state.killers[ply][1] = state.killers[ply][0];
        state.killers[ply][0] = move;
    }
}

fn quiescence(pos: *bitboard.Position, alpha_in: i32, beta: i32, state: *SearchState) i32 {
    state.nodes += 1;
    const stand_pat = evaluate.evaluate(pos);
    if (stand_pat >= beta) return beta;
    var alpha = if (alpha_in < stand_pat) stand_pat else alpha_in;

    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);
    sortMoves(pos, &list, 0, state, null);

    for (list.moves[0..list.count]) |move| {
        const is_capture = move.flags == @intFromEnum(movegen.MoveFlag.capture) or
                           move.flags == @intFromEnum(movegen.MoveFlag.ep_capture);
        if (!is_capture) continue;

        var next_pos = pos.*;
        if (!movegen.makeMove(&next_pos, move)) continue;

        const score = -quiescence(&next_pos, -beta, -alpha, state);
        if (score >= beta) return beta;
        if (score > alpha) alpha = score;
    }
    return alpha;
}

fn negamax(
    pos: *bitboard.Position,
    depth: u8,
    alpha_in: i32,
    beta_in: i32,
    ply: usize,
    state: *SearchState,
    allow_null: bool,
) i32 {
    state.nodes += 1;

    if (depth == 0) return quiescence(pos, alpha_in, beta_in, state);

    // TT probe
    var tt_move: ?movegen.Move = null;
    if (state.table.probe(pos.zobrist_hash)) |entry| {
        tt_move = entry.move;
        if (entry.depth >= depth) {
            switch (entry.bound) {
                .exact => return entry.score,
                .lower => if (entry.score >= beta_in) return entry.score,
                .upper => if (entry.score <= alpha_in) return entry.score,
            }
        }
    }

    const is_white = pos.side_to_move;
    const king_sq: u6 = @intCast(@ctz(if (is_white) pos.white_king else pos.black_king));
    const in_check = attacks.isSquareAttacked(pos, king_sq, !is_white);

    if (allow_null and !in_check and depth >= 3 and ply > 0) {
        const has_pieces = if (is_white)
            (pos.white_knights | pos.white_bishops | pos.white_rooks | pos.white_queens) != 0
        else
            (pos.black_knights | pos.black_bishops | pos.black_rooks | pos.black_queens) != 0;

        if (has_pieces) {
            var null_pos = pos.*;
            null_pos.side_to_move = !null_pos.side_to_move;
            null_pos.en_passant_sq = null;
            null_pos.zobrist_hash = zobrist.computeHash(&null_pos);

            const R: u8 = if (depth >= 6) 3 else 2;
            const null_score = -negamax(&null_pos, depth - 1 - R, -beta_in, -beta_in + 1, ply + 1, state, false);
            if (null_score >= beta_in) return beta_in;
        }
    }

    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);
    sortMoves(pos, &list, ply, state, tt_move);

    var alpha = alpha_in;
    var best_score: i32 = -INFINITY;
    var best_move: movegen.Move = list.moves[0];
    var legal_moves: u32 = 0;
    var bound: tt.Bound = .upper;

    for (list.moves[0..list.count]) |move| {
        var next_pos = pos.*;
        if (!movegen.makeMove(&next_pos, move)) continue;
        legal_moves += 1;

        const score = -negamax(&next_pos, depth - 1, -beta_in, -alpha, ply + 1, state, true);

        if (score > best_score) {
            best_score = score;
            best_move = move;
        }
        if (score > alpha) {
            alpha = score;
            bound = .exact;
        }
        if (alpha >= beta_in) {
            const is_capture = move.flags == @intFromEnum(movegen.MoveFlag.capture) or
                               move.flags == @intFromEnum(movegen.MoveFlag.ep_capture);
            if (!is_capture and ply < MAX_DEPTH) storeKiller(state, move, ply);
            bound = .lower;
            break;
        }
    }

    if (legal_moves == 0) {
        return if (in_check) -MATE_SCORE + @as(i32, @intCast(ply)) else 0;
    }

    state.table.store(pos.zobrist_hash, best_move, best_score, depth, bound);
    return best_score;
}

pub const SearchResult = struct {
    best_move: movegen.Move,
    score: i32,
    depth: u8,
    nodes: u64,
};

pub fn findBestMove(pos: *bitboard.Position, max_depth: u8, state: *SearchState) SearchResult {
    state.nodes = 0;

    var best_move: movegen.Move = undefined;
    var best_score: i32 = -INFINITY;

    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    for (list.moves[0..list.count]) |move| {
        var tmp = pos.*;
        if (movegen.makeMove(&tmp, move)) {
            best_move = move;
            break;
        }
    }

    var depth: u8 = 1;
    while (depth <= max_depth) : (depth += 1) {
        var alpha: i32 = -INFINITY;
        const beta: i32 = INFINITY;
        var iter_best = best_move;
        var iter_score: i32 = -INFINITY;

        var sorted_list = movegen.MoveList{};
        movegen.generateMoves(pos, &sorted_list);
        const tt_move = if (state.table.probe(pos.zobrist_hash)) |e| e.move else null;
        sortMoves(pos, &sorted_list, 0, state, tt_move);

        for (sorted_list.moves[0..sorted_list.count]) |move| {
            var next_pos = pos.*;
            if (!movegen.makeMove(&next_pos, move)) continue;

            const score = -negamax(&next_pos, depth - 1, -beta, -alpha, 1, state, true);

            if (score > iter_score) {
                iter_score = score;
                iter_best  = move;
            }
            if (score > alpha) alpha = score;
        }

        best_move  = iter_best;
        best_score = iter_score;

        std.debug.print("depth {} score {} nodes {}\n", .{ depth, best_score, state.nodes });

        if (best_score > MATE_SCORE - 100 or best_score < -MATE_SCORE + 100) break;
    }

    return .{
        .best_move = best_move,
        .score     = best_score,
        .depth     = max_depth,
        .nodes     = state.nodes,
    };
}
