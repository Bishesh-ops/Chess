const std = @import("std");
const bitboard = @import("bitboard.zig");
const attacks = @import("attacks.zig");

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
    quiet = 0,
    double_pawn_push = 1,
    king_castle = 2,
    queen_castle = 3,
    capture = 4,
    ep_capture = 5,
    promotion_knight = 8,
    promotion_bishop = 9,
    promotion_rook = 10,
    promotion_queen = 11,
};

const MAX_POSITION_MOVES = 256;

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
    const enemy = pos.getBlackPieces();
    const empty = pos.getEmptySquares();
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

        if ((pos.castling & bitboard.CastlingRights.WK) != 0) {
            if ((occupied & WK_EMPTY) == 0) {
                list.add(Move{ .source = sq, .target = 6, .flags = @intFromEnum(MoveFlag.king_castle) });
            }
        }

        if ((pos.castling & bitboard.CastlingRights.WQ) != 0) {
            if ((occupied & WQ_EMPTY) == 0) {
                list.add(Move{ .source = sq, .target = 2, .flags = @intFromEnum(MoveFlag.queen_castle) });
            }
        }

        king &= king - 1;
    }
}

pub fn generateBlackPieces(pos: *const bitboard.Position, list: *MoveList) void {
    const friendly = pos.getBlackPieces();
    const enemy = pos.getWhitePieces();
    const empty = pos.getEmptySquares();
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

        if ((pos.castling & bitboard.CastlingRights.BK) != 0) {
            if ((occupied & BK_EMPTY) == 0) {
                list.add(Move{ .source = sq, .target = 62, .flags = @intFromEnum(MoveFlag.king_castle) });
            }
        }

        if ((pos.castling & bitboard.CastlingRights.BQ) != 0) {
            if ((occupied & BQ_EMPTY) == 0) {
                list.add(Move{ .source = sq, .target = 58, .flags = @intFromEnum(MoveFlag.queen_castle) });
            }
        }

        king &= king - 1;
    }
}
pub fn generateWhitePawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty = pos.getEmptySquares();
    const enemies = pos.getBlackPieces();
    const pawns = pos.white_pawns;
    const promo_pawns = pawns & RANK_7;
    const normal_pawns = pawns & NOT_RANK_7;

    const single_pushes = (normal_pawns << 8) & empty;
    const double_pushes = (single_pushes << 8) & empty & (0xFF << (8 * 3));
    const captures_left = ((normal_pawns & NOT_A_FILE) << 7) & enemies;
    const captures_right = ((normal_pawns & NOT_H_FILE) << 9) & enemies;

    extractMoves(single_pushes, list, 8, MoveFlag.quiet);
    extractMoves(double_pushes, list, 16, MoveFlag.double_pawn_push);
    extractMoves(captures_left, list, 7, MoveFlag.capture);
    extractMoves(captures_right, list, 9, MoveFlag.capture);

    const promo_pushes = (promo_pawns << 8) & empty;
    const promo_caps_left = ((promo_pawns & NOT_A_FILE) << 7) & enemies;
    const promo_caps_right = ((promo_pawns & NOT_H_FILE) << 9) & enemies;

    extractPromotions(promo_pushes, list, 8);
    extractPromotions(promo_caps_left, list, 7);
    extractPromotions(promo_caps_right, list, 9);

    if (pos.en_passant_sq) |ep_sq| {
        const ep_mask = @as(u64, 1) << @intFromEnum(ep_sq);
        extractMoves(((pawns & NOT_A_FILE) << 7) & ep_mask, list, 7, MoveFlag.ep_capture);
        extractMoves(((pawns & NOT_H_FILE) << 9) & ep_mask, list, 9, MoveFlag.ep_capture);
    }
}

pub fn generateBlackPawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty = pos.getEmptySquares();
    const enemies = pos.getWhitePieces();
    const pawns = pos.black_pawns;
    const promo_pawns = pawns & RANK_2;
    const normal_pawns = pawns & NOT_RANK_2;

    const single_pushes = (normal_pawns >> 8) & empty;
    const double_pushes = (single_pushes >> 8) & empty & RANK_5;
    const captures_left = ((normal_pawns & NOT_A_FILE) >> 9) & enemies;
    const captures_right = ((normal_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackMoves(single_pushes, list, 8, MoveFlag.quiet);
    extractBlackMoves(double_pushes, list, 16, MoveFlag.double_pawn_push);
    extractBlackMoves(captures_left, list, 9, MoveFlag.capture);
    extractBlackMoves(captures_right, list, 7, MoveFlag.capture);

    const promo_pushes = (promo_pawns >> 8) & empty;
    const promo_caps_left = ((promo_pawns & NOT_A_FILE) >> 9) & enemies;
    const promo_caps_right = ((promo_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackPromotions(promo_pushes, list, 8);
    extractBlackPromotions(promo_caps_left, list, 9);
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
        const target_sq = @ctz(b);
        list.add(Move{
            .source = source,
            .target = @as(u6, @intCast(target_sq)),
            .flags = @intFromEnum(flag),
        });
        b &= b - 1;
    }
}

fn extractMoves(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    var b = board;
    while (b != 0) {
        const target_sq = @ctz(b);
        list.add(Move{
            .source = @as(u6, @intCast(target_sq - shift_amount)),
            .target = @as(u6, @intCast(target_sq)),
            .flags = @intFromEnum(flag),
        });
        b &= b - 1;
    }
}

fn extractPromotions(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    var b = board;
    while (b != 0) {
        const target_sq = @ctz(b);
        const source_sq = @as(u6, @intCast(target_sq - shift_amount));
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_knight) });
        b &= b - 1;
    }
}

fn extractBlackMoves(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    var b = board;
    while (b != 0) {
        const target_sq = @ctz(b);
        list.add(Move{
            .source = @as(u6, @intCast(target_sq + shift_amount)),
            .target = @as(u6, @intCast(target_sq)),
            .flags = @intFromEnum(flag),
        });
        b &= b - 1;
    }
}

fn extractBlackPromotions(board: bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    var b = board;
    while (b != 0) {
        const target_sq = @ctz(b);
        const source_sq = @as(u6, @intCast(target_sq + shift_amount));
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = source_sq, .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_knight) });
        b &= b - 1;
    }
}
