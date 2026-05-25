const std = @import("std");
const bitboard = @import("bitboard.zig");

const NOT_A_FILE: u64 = ~@as(u64, 0x0101010101010101);
const NOT_H_FILE: u64 = ~@as(u64, 0x8080808080808080);

const RANK_2: u64 = 0xFF << 8;
const RANK_3: u64 = 0xFF << (8 * 2);
const NOT_RANK_2: u64 = ~RANK_2;
const RANK_5: u64 = 0xFF << (8 * 4);
const RANK_7: u64 = 0xFF << (8 * 6);
const NOT_RANK_7: u64 = ~RANK_7;

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
    } else {
        generateBlackPawnMoves(pos, list);
    }
}

pub fn generateWhitePawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty = pos.getEmptySquares();
    const enemies = pos.getBlackPieces();

    const pawns = pos.white_pawns;
    const promo_pawns = pawns & RANK_7;
    const normal_pawns = pawns & NOT_RANK_7;

    var single_pushes = (normal_pawns << 8) & empty;
    var double_pushes = (single_pushes << 8) & empty & (0xFF << (8 * 3));
    var captures_left = ((normal_pawns & NOT_A_FILE) << 7) & enemies;
    var captures_right = ((normal_pawns & NOT_H_FILE) << 9) & enemies;

    extractMoves(&single_pushes, list, 8, MoveFlag.quiet);
    extractMoves(&double_pushes, list, 16, MoveFlag.double_pawn_push);
    extractMoves(&captures_left, list, 7, MoveFlag.capture);
    extractMoves(&captures_right, list, 9, MoveFlag.capture);

    var promo_pushes = (promo_pawns << 8) & empty;
    var promo_caps_left = ((promo_pawns & NOT_A_FILE) << 7) & enemies;
    var promo_caps_right = ((promo_pawns & NOT_H_FILE) << 9) & enemies;

    extractPromotions(&promo_pushes, list, 8);
    extractPromotions(&promo_caps_left, list, 7);
    extractPromotions(&promo_caps_right, list, 9);

    if (pos.en_passant_sq) |ep_sq| {
        const ep_mask = @as(u64, 1) << @intFromEnum(ep_sq);

        var ep_left = ((pawns & NOT_A_FILE) << 7) & ep_mask;
        extractMoves(&ep_left, list, 7, MoveFlag.ep_capture);

        var ep_right = ((pawns & NOT_H_FILE) << 9) & ep_mask;
        extractMoves(&ep_right, list, 9, MoveFlag.ep_capture);
    }
}

pub fn generateBlackPawnMoves(pos: *const bitboard.Position, list: *MoveList) void {
    const empty = pos.getEmptySquares();
    const enemies = pos.getWhitePieces();

    const pawns = pos.black_pawns;
    const promo_pawns = pawns & RANK_2;
    const normal_pawns = pawns & NOT_RANK_2;

    var single_pushes = (normal_pawns >> 8) & empty;
    var double_pushes = (single_pushes >> 8) & empty & RANK_5;
    var captures_left = ((normal_pawns & NOT_A_FILE) >> 9) & enemies;
    var captures_right = ((normal_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackMoves(&single_pushes, list, 8, MoveFlag.quiet);
    extractBlackMoves(&double_pushes, list, 16, MoveFlag.double_pawn_push);
    extractBlackMoves(&captures_left, list, 9, MoveFlag.capture);
    extractBlackMoves(&captures_right, list, 7, MoveFlag.capture);

    var promo_pushes = (promo_pawns >> 8) & empty;
    var promo_caps_left = ((promo_pawns & NOT_A_FILE) >> 9) & enemies;
    var promo_caps_right = ((promo_pawns & NOT_H_FILE) >> 7) & enemies;

    extractBlackPromotions(&promo_pushes, list, 8);
    extractBlackPromotions(&promo_caps_left, list, 9);
    extractBlackPromotions(&promo_caps_right, list, 7);

    if (pos.en_passant_sq) |ep_sq| {
        const ep_mask = @as(u64, 1) << @intFromEnum(ep_sq);

        var ep_left = ((pawns & NOT_A_FILE) >> 9) & ep_mask;
        extractBlackMoves(&ep_left, list, 9, MoveFlag.ep_capture);

        var ep_right = ((pawns & NOT_H_FILE) >> 7) & ep_mask;
        extractBlackMoves(&ep_right, list, 7, MoveFlag.ep_capture);
    }
}

fn extractMoves(board: *bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    while (board.* != 0) {
        const target_sq = @ctz(board.*);
        const source_sq = target_sq - shift_amount;

        list.add(Move{
            .source = @as(u6, @intCast(source_sq)),
            .target = @as(u6, @intCast(target_sq)),
            .flags = @intFromEnum(flag),
        });

        board.* &= board.* - 1;
    }
}

fn extractPromotions(board: *bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    while (board.* != 0) {
        const target_sq = @ctz(board.*);
        const source_sq = target_sq - shift_amount;

        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_knight) });

        board.* &= board.* - 1;
    }
}

fn extractBlackMoves(board: *bitboard.Bitboard, list: *MoveList, shift_amount: u6, flag: MoveFlag) void {
    while (board.* != 0) {
        const target_sq = @ctz(board.*);
        const source_sq = target_sq + shift_amount;

        list.add(Move{
            .source = @as(u6, @intCast(source_sq)),
            .target = @as(u6, @intCast(target_sq)),
            .flags = @intFromEnum(flag),
        });

        board.* &= board.* - 1;
    }
}

fn extractBlackPromotions(board: *bitboard.Bitboard, list: *MoveList, shift_amount: u6) void {
    while (board.* != 0) {
        const target_sq = @ctz(board.*);
        const source_sq = target_sq + shift_amount;

        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_queen) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_rook) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_bishop) });
        list.add(Move{ .source = @as(u6, @intCast(source_sq)), .target = @as(u6, @intCast(target_sq)), .flags = @intFromEnum(MoveFlag.promotion_knight) });

        board.* &= board.* - 1;
    }
}
