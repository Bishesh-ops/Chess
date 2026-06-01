const std = @import("std");
const bitboard = @import("bitboard.zig");
const attacks = @import("attacks.zig");
const zobrist = @import("zobrist.zig");

const NOT_A_FILE: u64 = ~@as(u64, 0x0101010101010101);
const NOT_H_FILE: u64 = ~@as(u64, 0x8080808080808080);

const RANK_2: u64 = 0xFF << 8;
const NOT_RANK_2: u64 = ~RANK_2;
const RANK_3: u64 = 0xFF << (8 * 2);
const RANK_5: u64 = 0xFF << (8 * 4);
const RANK_7: u64 = 0xFF << (8 * 6);
const NOT_RANK_7: u64 = ~RANK_7;

const WK_EMPTY: u64 = (@as(u64, 1) << 5) | (@as(u64, 1) << 6);
const WQ_EMPTY: u64 = (@as(u64, 1) << 1) | (@as(u64, 1) << 2) | (@as(u64, 1) << 3);
const BK_EMPTY: u64 = (@as(u64, 1) << 61) | (@as(u64, 1) << 62);
const BQ_EMPTY: u64 = (@as(u64, 1) << 57) | (@as(u64, 1) << 58) | (@as(u64, 1) << 59);

pub const Move = packed struct {
    source: u6,
    target: u6,
    flags: u4,
};

pub const MoveFlag = enum(u4) {
    quiet            = 0,
    double_pawn_push = 1,
    king_castle      = 2,
    queen_castle     = 3,
    capture          = 4,
    ep_capture       = 5,
    promotion_knight = 8,
    promotion_bishop = 9,
    promotion_rook   = 10,
    promotion_queen  = 11,
};

pub const MAX_POSITION_MOVES = 256;

pub const MoveList = struct {
    moves: [MAX_POSITION_MOVES]Move = undefined,
    count: usize = 0,

    pub fn add(self: *MoveList, move: Move) void {
        self.moves[self.count] = move;
        self.count += 1;
    }
};

pub fn generateMoves(pos: *const bitboard.Position, list: *MoveList) void {
    if (pos.side_to_move) {
        generateWhitePawnMoves(pos, list);
        generateWhitePieces(pos, list);
    } else {
        generateBlackPawnMoves(pos, list);
        generateBlackPieces(pos, list);
    }
}

pub fn generateWhitePieces(pos: *const bitboard.Position, list: *MoveList) void {
    const friendly = pos.getWhitePieces();
    const enemy    = pos.getBlackPieces();
    const empty    = pos.getEmptySquares();
    const occupied = pos.getOccupied();

    var knights = pos.white_knights;
    while (knights != 0) {
        const sq: u6 = @intCast(@ctz(knights));
        const att = attacks.getKnightAttacks(sq) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        knights &= knights - 1;
    }

    var bishops = pos.white_bishops;
    while (bishops != 0) {
        const sq: u6 = @intCast(@ctz(bishops));
        const att = attacks.getBishopAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        bishops &= bishops - 1;
    }

    var rooks = pos.white_rooks;
    while (rooks != 0) {
        const sq: u6 = @intCast(@ctz(rooks));
        const att = attacks.getRookAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        rooks &= rooks - 1;
    }

    var queens = pos.white_queens;
    while (queens != 0) {
        const sq: u6 = @intCast(@ctz(queens));
        const att = attacks.getQueenAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        queens &= queens - 1;
    }

    var king = pos.white_king;
    while (king != 0) {
        const sq: u6 = @intCast(@ctz(king));
        const att = attacks.getKingAttacks(sq) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        if ((pos.castling & bitboard.CastlingRights.WK) != 0 and (occupied & WK_EMPTY) == 0)
            list.add(Move{ .source = sq, .target = 6, .flags = @intFromEnum(MoveFlag.king_castle) });
        if ((pos.castling & bitboard.CastlingRights.WQ) != 0 and (occupied & WQ_EMPTY) == 0)
            list.add(Move{ .source = sq, .target = 2, .flags = @intFromEnum(MoveFlag.queen_castle) });
        king &= king - 1;
    }
}

pub fn generateBlackPieces(pos: *const bitboard.Position, list: *MoveList) void {
    const friendly = pos.getBlackPieces();
    const enemy    = pos.getWhitePieces();
    const empty    = pos.getEmptySquares();
    const occupied = pos.getOccupied();

    var knights = pos.black_knights;
    while (knights != 0) {
        const sq: u6 = @intCast(@ctz(knights));
        const att = attacks.getKnightAttacks(sq) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        knights &= knights - 1;
    }

    var bishops = pos.black_bishops;
    while (bishops != 0) {
        const sq: u6 = @intCast(@ctz(bishops));
        const att = attacks.getBishopAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        bishops &= bishops - 1;
    }

    var rooks = pos.black_rooks;
    while (rooks != 0) {
        const sq: u6 = @intCast(@ctz(rooks));
        const att = attacks.getRookAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        rooks &= rooks - 1;
    }

    var queens = pos.black_queens;
    while (queens != 0) {
        const sq: u6 = @intCast(@ctz(queens));
        const att = attacks.getQueenAttacks(sq, occupied) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        queens &= queens - 1;
    }

    var king = pos.black_king;
    while (king != 0) {
        const sq: u6 = @intCast(@ctz(king));
        const att = attacks.getKingAttacks(sq) & ~friendly;
        extractStandard(sq, att & empty, list, MoveFlag.quiet);
        extractStandard(sq, att & enemy, list, MoveFlag.capture);
        if ((pos.castling & bitboard.CastlingRights.BK) != 0 and (occupied & BK_EMPTY) == 0)
            list.add(Move{ .source = sq, .target = 62, .flags = @intFromEnum(MoveFlag.king_castle) });
        if ((pos.castling & bitboard.CastlingRights.BQ) != 0 and (occupied & BQ_EMPTY) == 0)
            list.add(Move{ .source = sq, .target = 58, .flags = @intFromEnum(MoveFlag.queen_castle) });
        king &= king - 1;
    }
}

pub fn generateWhitePawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty   = pos.getEmptySquares();
    const enemies = pos.getBlackPieces();
    const pawns   = pos.white_pawns;

    const promo_pawns  = pawns & RANK_7;
    const normal_pawns = pawns & NOT_RANK_7;

    const single_pushes  = (normal_pawns << 8) & empty;
    const double_pushes  = (single_pushes << 8) & empty & (0xFF << (8 * 3));
    const captures_left  = ((normal_pawns & NOT_A_FILE) << 7) & enemies;
    const captures_right = ((normal_pawns & NOT_H_FILE) << 9) & enemies;

    extractMoves(single_pushes,  list, 8,  MoveFlag.quiet);
    extractMoves(double_pushes,  list, 16, MoveFlag.double_pawn_push);
    extractMoves(captures_left,  list, 7,  MoveFlag.capture);
    extractMoves(captures_right, list, 9,  MoveFlag.capture);

    const promo_pushes    = (promo_pawns << 8) & empty;
    const promo_caps_left = ((promo_pawns & NOT_A_FILE) << 7) & enemies;
    const promo_caps_right = ((promo_pawns & NOT_H_FILE) << 9) & enemies;

    extractPromotions(promo_pushes,     list, 8);
    extractPromotions(promo_caps_left,  list, 7);
    extractPromotions(promo_caps_right, list, 9);

    if (pos.en_passant_sq) |ep_sq| {
        const ep_mask = @as(u64, 1) << @intFromEnum(ep_sq);
        extractMoves(((pawns & NOT_A_FILE) << 7) & ep_mask, list, 7, MoveFlag.ep_capture);
        extractMoves(((pawns & NOT_H_FILE) << 9) & ep_mask, list, 9, MoveFlag.ep_capture);
    }
}

pub fn generateBlackPawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty   = pos.getEmptySquares();
    const enemies = pos.getWhitePieces();
    const pawns   = pos.black_pawns;

    const promo_pawns  = pawns & RANK_2;
    const normal_pawns = pawns & NOT_RANK_2;

    const single_pushes  = (normal_pawns >> 8) & empty;
    const double_pushes  = (single_pushes >> 8) & empty & RANK_5;
    const captures_left  = ((normal_pawns & NOT_A_FILE) >> 9) & enemies;
    const captures_right = ((normal_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackMoves(single_pushes,  list, 8,  MoveFlag.quiet);
    extractBlackMoves(double_pushes,  list, 16, MoveFlag.double_pawn_push);
    extractBlackMoves(captures_left,  list, 9,  MoveFlag.capture);
    extractBlackMoves(captures_right, list, 7,  MoveFlag.capture);

    const promo_pushes     = (promo_pawns >> 8) & empty;
    const promo_caps_left  = ((promo_pawns & NOT_A_FILE) >> 9) & enemies;
    const promo_caps_right = ((promo_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackPromotions(promo_pushes,     list, 8);
    extractBlackPromotions(promo_caps_left,  list, 9);
    extractBlackPromotions(promo_caps_right, list, 7);

    if (pos.en_passant_sq) |ep_sq| {
        const ep_mask = @as(u64, 1) << @intFromEnum(ep_sq);
        extractBlackMoves(((pawns & NOT_A_FILE) >> 9) & ep_mask, list, 9, MoveFlag.ep_capture);
        extractBlackMoves(((pawns & NOT_H_FILE) >> 7) & ep_mask, list, 7, MoveFlag.ep_capture);
    }
}

fn extractStandard(source: u6, board: bitboard.Bitboard, list: *MoveList, flag: MoveFlag) void {
    var b = board;
    while (b != 0) {
        list.add(Move{ .source = source, .target = @as(u6, @intCast(@ctz(b))), .flags = @intFromEnum(flag) });
        b &= b - 1;
    }
}

fn extractMoves(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    var b = board;
    while (b != 0) {
        const t = @ctz(b);
        list.add(Move{ .source = @as(u6, @intCast(t - shift_amount)), .target = @as(u6, @intCast(t)), .flags = @intFromEnum(flag) });
        b &= b - 1;
    }
}

fn extractPromotions(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    var b = board;
    while (b != 0) {
        const t  = @ctz(b);
        const src = @as(u6, @intCast(t - shift_amount));
        const tgt = @as(u6, @intCast(t));
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_knight) });
        b &= b - 1;
    }
}

fn extractBlackMoves(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    var b = board;
    while (b != 0) {
        const t = @ctz(b);
        list.add(Move{ .source = @as(u6, @intCast(t + shift_amount)), .target = @as(u6, @intCast(t)), .flags = @intFromEnum(flag) });
        b &= b - 1;
    }
}

fn extractBlackPromotions(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    var b = board;
    while (b != 0) {
        const t   = @ctz(b);
        const src = @as(u6, @intCast(t + shift_amount));
        const tgt = @as(u6, @intCast(t));
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = src, .target = tgt, .flags = @intFromEnum(MoveFlag.promotion_knight) });
        b &= b - 1;
    }
}

const CASTLE_RIGHTS = initCastleRights();
fn initCastleRights() [64]u4 {
    var rights = [_]u4{15} ** 64;
    rights[4]  = 15 ^ bitboard.CastlingRights.WK ^ bitboard.CastlingRights.WQ;
    rights[0]  = 15 ^ bitboard.CastlingRights.WQ;
    rights[7]  = 15 ^ bitboard.CastlingRights.WK;
    rights[60] = 15 ^ bitboard.CastlingRights.BK ^ bitboard.CastlingRights.BQ;
    rights[56] = 15 ^ bitboard.CastlingRights.BQ;
    rights[63] = 15 ^ bitboard.CastlingRights.BK;
    return rights;
}

fn clearSquare(pos: *bitboard.Position, sq: u6) void {
    const mask = ~(@as(u64, 1) << sq);
    pos.white_pawns   &= mask;
    pos.white_knights &= mask;
    pos.white_bishops &= mask;
    pos.white_rooks   &= mask;
    pos.white_queens  &= mask;
    pos.white_king    &= mask;
    pos.black_pawns   &= mask;
    pos.black_knights &= mask;
    pos.black_bishops &= mask;
    pos.black_rooks   &= mask;
    pos.black_queens  &= mask;
    pos.black_king    &= mask;
}

// Returns the Zobrist piece index for whatever piece is at `sq`, or null.
fn zobristPieceAt(pos: *const bitboard.Position, sq: u6) ?usize {
    const mask = @as(u64, 1) << sq;
    if (pos.white_pawns   & mask != 0) return zobrist.PieceIndex.WP;
    if (pos.white_knights & mask != 0) return zobrist.PieceIndex.WN;
    if (pos.white_bishops & mask != 0) return zobrist.PieceIndex.WB;
    if (pos.white_rooks   & mask != 0) return zobrist.PieceIndex.WR;
    if (pos.white_queens  & mask != 0) return zobrist.PieceIndex.WQ;
    if (pos.white_king    & mask != 0) return zobrist.PieceIndex.WK;
    if (pos.black_pawns   & mask != 0) return zobrist.PieceIndex.BP;
    if (pos.black_knights & mask != 0) return zobrist.PieceIndex.BN;
    if (pos.black_bishops & mask != 0) return zobrist.PieceIndex.BB;
    if (pos.black_rooks   & mask != 0) return zobrist.PieceIndex.BR;
    if (pos.black_queens  & mask != 0) return zobrist.PieceIndex.BQ;
    if (pos.black_king    & mask != 0) return zobrist.PieceIndex.BK;
    return null;
}

pub fn makeMove(pos: *bitboard.Position, move: Move) bool {
    const source_mask = @as(u64, 1) << move.source;
    const target_mask = @as(u64, 1) << move.target;
    const is_white    = pos.side_to_move;
    const flag        = move.flags;

    var hash = pos.zobrist_hash;

    // Remove old castling and EP contributions before modifying the position
    hash ^= zobrist.CASTLING_KEYS[pos.castling];
    if (pos.en_passant_sq) |ep| hash ^= zobrist.EP_KEYS[@intFromEnum(ep) % 8];

    // Remove the moving piece from its source square in the hash
    if (zobristPieceAt(pos, move.source)) |pi| hash ^= zobrist.PIECE_KEYS[pi][move.source];

    // Remove captured piece (or EP pawn) from hash
    if (flag == @intFromEnum(MoveFlag.ep_capture)) {
        const ep_sq: u6 = if (is_white) move.target - 8 else move.target + 8;
        if (zobristPieceAt(pos, ep_sq)) |pi| hash ^= zobrist.PIECE_KEYS[pi][ep_sq];
        clearSquare(pos, ep_sq);
    } else {
        if (zobristPieceAt(pos, move.target)) |pi| hash ^= zobrist.PIECE_KEYS[pi][move.target];
        clearSquare(pos, move.target);
    }

    // Move the piece on the board
    if ((pos.white_pawns & source_mask) != 0) {
        pos.white_pawns ^= source_mask;
        if      (flag == @intFromEnum(MoveFlag.promotion_queen))  { pos.white_queens  |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WQ][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_rook))   { pos.white_rooks   |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_bishop)) { pos.white_bishops |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WB][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_knight)) { pos.white_knights |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WN][move.target]; }
        else                                                       { pos.white_pawns   |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WP][move.target]; }
    } else if ((pos.black_pawns & source_mask) != 0) {
        pos.black_pawns ^= source_mask;
        if      (flag == @intFromEnum(MoveFlag.promotion_queen))  { pos.black_queens  |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BQ][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_rook))   { pos.black_rooks   |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_bishop)) { pos.black_bishops |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BB][move.target]; }
        else if (flag == @intFromEnum(MoveFlag.promotion_knight)) { pos.black_knights |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BN][move.target]; }
        else                                                       { pos.black_pawns   |= target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BP][move.target]; }
    } else if ((pos.white_knights & source_mask) != 0) { pos.white_knights ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WN][move.target];
    } else if ((pos.black_knights & source_mask) != 0) { pos.black_knights ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BN][move.target];
    } else if ((pos.white_bishops & source_mask) != 0) { pos.white_bishops ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WB][move.target];
    } else if ((pos.black_bishops & source_mask) != 0) { pos.black_bishops ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BB][move.target];
    } else if ((pos.white_rooks   & source_mask) != 0) { pos.white_rooks   ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][move.target];
    } else if ((pos.black_rooks   & source_mask) != 0) { pos.black_rooks   ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][move.target];
    } else if ((pos.white_queens  & source_mask) != 0) { pos.white_queens  ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WQ][move.target];
    } else if ((pos.black_queens  & source_mask) != 0) { pos.black_queens  ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BQ][move.target];
    } else if ((pos.white_king    & source_mask) != 0) { pos.white_king    ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WK][move.target];
    } else if ((pos.black_king    & source_mask) != 0) { pos.black_king    ^= source_mask | target_mask; hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BK][move.target];
    }

    // Castling rook moves
    if (flag == @intFromEnum(MoveFlag.king_castle)) {
        if (is_white) {
            pos.white_rooks ^= (@as(u64, 1) << 7) | (@as(u64, 1) << 5);
            hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][7] ^ zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][5];
        } else {
            pos.black_rooks ^= (@as(u64, 1) << 63) | (@as(u64, 1) << 61);
            hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][63] ^ zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][61];
        }
    } else if (flag == @intFromEnum(MoveFlag.queen_castle)) {
        if (is_white) {
            pos.white_rooks ^= (@as(u64, 1) << 0) | (@as(u64, 1) << 3);
            hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][0] ^ zobrist.PIECE_KEYS[zobrist.PieceIndex.WR][3];
        } else {
            pos.black_rooks ^= (@as(u64, 1) << 56) | (@as(u64, 1) << 59);
            hash ^= zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][56] ^ zobrist.PIECE_KEYS[zobrist.PieceIndex.BR][59];
        }
    }

    pos.castling &= CASTLE_RIGHTS[move.source] & CASTLE_RIGHTS[move.target];
    hash ^= zobrist.CASTLING_KEYS[pos.castling];

    pos.en_passant_sq = null;
    if (flag == @intFromEnum(MoveFlag.double_pawn_push)) {
        const ep_sq: u6 = if (is_white) move.target - 8 else move.target + 8;
        pos.en_passant_sq = @as(bitboard.Square, @enumFromInt(ep_sq));
        hash ^= zobrist.EP_KEYS[ep_sq % 8];
    }

    hash ^= zobrist.SIDE_KEY;
    pos.side_to_move = !pos.side_to_move;
    pos.zobrist_hash = hash;

    const king_sq: u6 = @intCast(@ctz(if (is_white) pos.white_king else pos.black_king));
    const in_check = attacks.isSquareAttacked(pos, king_sq, pos.side_to_move);
    return !in_check;
}
