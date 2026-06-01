const std = @import("std");

pub const Bitboard = u64;

pub const Square = enum(u6) {
    a1, b1, c1, d1, e1, f1, g1, h1,
    a2, b2, c2, d2, e2, f2, g2, h2,
    a3, b3, c3, d3, e3, f3, g3, h3,
    a4, b4, c4, d4, e4, f4, g4, h4,
    a5, b5, c5, d5, e5, f5, g5, h5,
    a6, b6, c6, d6, e6, f6, g6, h6,
    a7, b7, c7, d7, e7, f7, g7, h7,
    a8, b8, c8, d8, e8, f8, g8, h8,
};

pub const CastlingRights = struct {
    pub const WK: u4 = 1; 
    pub const WQ: u4 = 2; 
    pub const BK: u4 = 4; 
    pub const BQ: u4 = 8; 
};

pub const Position = struct {
    white_pawns: Bitboard = 0,
    white_knights: Bitboard = 0,
    white_bishops: Bitboard = 0,
    white_rooks: Bitboard = 0,
    white_queens: Bitboard = 0,
    white_king: Bitboard = 0,

    black_pawns: Bitboard = 0,
    black_knights: Bitboard = 0,
    black_bishops: Bitboard = 0,
    black_rooks: Bitboard = 0,
    black_queens: Bitboard = 0,
    black_king: Bitboard = 0,

    side_to_move: bool = true, 
    en_passant_sq: ?Square = null,
    castling: u4 = 0, 

    pub fn initStart() Position {
        return loadFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") catch unreachable;
    }

    pub fn getWhitePieces(self: *const Position) Bitboard {
        return self.white_pawns | self.white_knights | self.white_bishops | 
               self.white_rooks | self.white_queens | self.white_king;
    }

    pub fn getBlackPieces(self: *const Position) Bitboard {
        return self.black_pawns | self.black_knights | self.black_bishops | 
               self.black_rooks | self.black_queens | self.black_king;
    }

    pub fn getOccupied(self: *const Position) Bitboard {
        return self.getWhitePieces() | self.getBlackPieces();
    }

    pub fn getEmptySquares(self: *const Position) Bitboard {
        return ~self.getOccupied();
    }

    pub fn loadFen(fen: []const u8) !Position {
        var pos = Position{};
        var iter = std.mem.splitScalar(u8, fen, ' ');

        const pieces_str = iter.next() orelse return error.InvalidFen;
        var rank: i8 = 7;
        var file: i8 = 0;
        
        for (pieces_str) |c| {
            if (c == '/') {
                rank -= 1;
                file = 0;
            } else if (c >= '1' and c <= '8') {
                file += @as(i8, @intCast(c - '0'));
            } else {
                const sq = @as(u6, @intCast(rank * 8 + file));
                const mask = @as(u64, 1) << sq;
                switch (c) {
                    'P' => pos.white_pawns |= mask,
                    'N' => pos.white_knights |= mask,
                    'B' => pos.white_bishops |= mask,
                    'R' => pos.white_rooks |= mask,
                    'Q' => pos.white_queens |= mask,
                    'K' => pos.white_king |= mask,
                    'p' => pos.black_pawns |= mask,
                    'n' => pos.black_knights |= mask,
                    'b' => pos.black_bishops |= mask,
                    'r' => pos.black_rooks |= mask,
                    'q' => pos.black_queens |= mask,
                    'k' => pos.black_king |= mask,
                    else => return error.InvalidFenPiece,
                }
                file += 1;
            }
        }

        const turn_str = iter.next() orelse return error.InvalidFen;
        pos.side_to_move = turn_str[0] == 'w';

        const castle_str = iter.next() orelse return error.InvalidFen;
        if (castle_str[0] != '-') {
            for (castle_str) |c| {
                switch (c) {
                    'K' => pos.castling |= CastlingRights.WK,
                    'Q' => pos.castling |= CastlingRights.WQ,
                    'k' => pos.castling |= CastlingRights.BK,
                    'q' => pos.castling |= CastlingRights.BQ,
                    else => {},
                }
            }
        }

        const ep_str = iter.next() orelse return error.InvalidFen;
        if (ep_str[0] != '-') {
            const ep_file = ep_str[0] - 'a';
            const ep_rank = ep_str[1] - '1';
            pos.en_passant_sq = @as(Square, @enumFromInt(ep_rank * 8 + ep_file));
        }

        return pos;
    }

   pub fn toFen(self: *const Position, buffer: []u8) ![]const u8 {
    var w = std.Io.Writer.fixed(buffer);

    var rank: i8 = 7;
    while (rank >= 0) : (rank -= 1) {
        var empty_count: u8 = 0;
        var file: i8 = 0;
        while (file < 8) : (file += 1) {
            const sq = @as(u6, @intCast(rank * 8 + file));
            const mask = @as(u64, 1) << sq;

            var piece: u8 = 0;
            if ((self.white_pawns & mask) != 0) { piece = 'P'; }
            else if ((self.white_knights & mask) != 0) { piece = 'N'; }
            else if ((self.white_bishops & mask) != 0) { piece = 'B'; }
            else if ((self.white_rooks & mask) != 0) { piece = 'R'; }
            else if ((self.white_queens & mask) != 0) { piece = 'Q'; }
            else if ((self.white_king & mask) != 0) { piece = 'K'; }
            else if ((self.black_pawns & mask) != 0) { piece = 'p'; }
            else if ((self.black_knights & mask) != 0) { piece = 'n'; }
            else if ((self.black_bishops & mask) != 0) { piece = 'b'; }
            else if ((self.black_rooks & mask) != 0) { piece = 'r'; }
            else if ((self.black_queens & mask) != 0) { piece = 'q'; }
            else if ((self.black_king & mask) != 0) { piece = 'k'; }

            if (piece == 0) {
                empty_count += 1;
            } else {
                if (empty_count > 0) {
                    try w.print("{d}", .{empty_count});
                    empty_count = 0;
                }
                try w.print("{c}", .{piece});
            }
        }
        if (empty_count > 0) {
            try w.print("{d}", .{empty_count});
        }
        if (rank > 0) {
            try w.print("/", .{});
        }
    }

    try w.print(" {c} ", .{if (self.side_to_move) @as(u8, 'w') else @as(u8, 'b')});

    if (self.castling == 0) {
        try w.print("-", .{});
    } else {
        if ((self.castling & CastlingRights.WK) != 0) { try w.print("K", .{}); }
        if ((self.castling & CastlingRights.WQ) != 0) { try w.print("Q", .{}); }
        if ((self.castling & CastlingRights.BK) != 0) { try w.print("k", .{}); }
        if ((self.castling & CastlingRights.BQ) != 0) { try w.print("q", .{}); }
    }

    try w.print(" ", .{});
    if (self.en_passant_sq) |sq| {
        const sq_val = @intFromEnum(sq);
        const f = @as(u8, @intCast(sq_val % 8));
        const r = @as(u8, @intCast(sq_val / 8));
        try w.print("{c}{c}", .{ 'a' + f, '1' + r });
    } else {
        try w.print("-", .{});
    }

    try w.print(" 0 1", .{});

    return buffer[0..w.pos];
}
    pub fn printBoard(self: *const Position) void {
        const print = @import("std").debug.print;
        print("\n", .{});
        var rank: i8 = 7;
        while (rank >= 0) : (rank -= 1) {
            print(" {} ", .{rank + 1}); 
            var file: i8 = 0;
            while (file < 8) : (file += 1) {
                const sq = @as(u6, @intCast(rank * 8 + file));
                const mask = @as(u64, 1) << sq;
                var piece_str: []const u8 = " "; 
                if ((self.white_pawns & mask) != 0) { piece_str = "♙"; } 
                else if ((self.white_knights & mask) != 0) { piece_str = "♘"; } 
                else if ((self.white_bishops & mask) != 0) { piece_str = "♗"; } 
                else if ((self.white_rooks & mask) != 0) { piece_str = "♖"; } 
                else if ((self.white_queens & mask) != 0) { piece_str = "♕"; } 
                else if ((self.white_king & mask) != 0) { piece_str = "♔"; } 
                else if ((self.black_pawns & mask) != 0) { piece_str = "♟"; } 
                else if ((self.black_knights & mask) != 0) { piece_str = "♞"; } 
                else if ((self.black_bishops & mask) != 0) { piece_str = "♝"; } 
                else if ((self.black_rooks & mask) != 0) { piece_str = "♜"; } 
                else if ((self.black_queens & mask) != 0) { piece_str = "♛"; } 
                else if ((self.black_king & mask) != 0) { piece_str = "♚"; }

                const is_light_square = @rem(rank + file, 2) != 0;
                if (is_light_square) {
                    print("\x1b[47m\x1b[30m {s} \x1b[0m", .{piece_str});
                } else {
                    print("\x1b[100m\x1b[97m {s} \x1b[0m", .{piece_str});
                }
            }
            print("\n", .{}); 
        }
        print("    a  b  c  d  e  f  g  h\n\n", .{});
    }
};
