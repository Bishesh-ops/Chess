const std = @import("std");

pub const Bitboard = u64;

pub const Square = enum(u6) {
    a1,
    b1,
    c1,
    d1,
    e1,
    f1,
    g1,
    h1,
    a2,
    b2,
    c2,
    d2,
    e2,
    f2,
    g2,
    h2,
    a3,
    b3,
    c3,
    d3,
    e3,
    f3,
    g3,
    h3,
    a4,
    b4,
    c4,
    d4,
    e4,
    f4,
    g4,
    h4,
    a5,
    b5,
    c5,
    d5,
    e5,
    f5,
    g5,
    h5,
    a6,
    b6,
    c6,
    d6,
    e6,
    f6,
    g6,
    h6,
    a7,
    b7,
    c7,
    d7,
    e7,
    f7,
    g7,
    h7,
    a8,
    b8,
    c8,
    d8,
    e8,
    f8,
    g8,
    h8,
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

    side_to_move: bool = true, // white = true, black = false;
    en_passant_sq: ?Square = null,

    pub fn getEmptySquares(self: *const Position) Bitboard {
        return ~self.getOccupied();
    }

    // Sets up the standard chess starting position
    pub fn initStart() Position {
        var pos = Position{};

        // --- Pawns ---
        pos.white_pawns = 0xFF << 8;
        pos.black_pawns = 0xFF << (8 * 6);

        // --- Knights ---
        pos.white_knights = (1 << @intFromEnum(Square.b1)) | (1 << @intFromEnum(Square.g1));
        pos.black_knights = (1 << @intFromEnum(Square.b8)) | (1 << @intFromEnum(Square.g8));

        // --- Bishops ---
        pos.white_bishops = (1 << @intFromEnum(Square.c1)) | (1 << @intFromEnum(Square.f1));
        pos.black_bishops = (1 << @intFromEnum(Square.c8)) | (1 << @intFromEnum(Square.f8));

        // --- Rooks ---
        pos.white_rooks = (1 << @intFromEnum(Square.a1)) | (1 << @intFromEnum(Square.h1));
        pos.black_rooks = (1 << @intFromEnum(Square.a8)) | (1 << @intFromEnum(Square.h8));

        // --- Queens ---
        pos.white_queens = 1 << @intFromEnum(Square.d1);
        pos.black_queens = 1 << @intFromEnum(Square.d8);

        // --- Kings ---
        pos.white_king = 1 << @intFromEnum(Square.e1);
        pos.black_king = 1 << @intFromEnum(Square.e8);

        pos.side_to_move = true;

        return pos;
    }
    pub fn getWhitePieces(self: *const Position) Bitboard {
        return self.white_pawns |
            self.white_knights |
            self.white_bishops |
            self.white_rooks |
            self.white_queens |
            self.white_king;
    }

    pub fn getBlackPieces(self: *const Position) Bitboard {
        return self.black_pawns |
            self.black_knights |
            self.black_bishops |
            self.black_rooks |
            self.black_queens |
            self.black_king;
    }

    pub fn getOccupied(self: *const Position) Bitboard {
        return self.getWhitePieces() | self.getBlackPieces();
    }

    pub fn printBoard(self: *const Position) void {
        std.debug.print("\n  +------------------------+\n", .{});

        var rank: i8 = 7;
        while (rank >= 0) : (rank -= 1) {
            std.debug.print("{} |", .{rank + 1});

            var file: i8 = 0;
            while (file < 8) : (file += 1) {
                const square_index = @as(u6, @intCast(rank * 8 + file));
                const mask = @as(u64, 1) << square_index;
                var char: u8 = '.'; // Default to empty square

                // --- Check White Pieces ---
                if ((self.white_pawns & mask) != 0) {
                    char = 'P';
                } else if ((self.white_knights & mask) != 0) {
                    char = 'N';
                } else if ((self.white_bishops & mask) != 0) {
                    char = 'B';
                } else if ((self.white_rooks & mask) != 0) {
                    char = 'R';
                } else if ((self.white_queens & mask) != 0) {
                    char = 'Q';
                } else if ((self.white_king & mask) != 0) {
                    char = 'K';
                }
                // --- Check Black Pieces ---
                else if ((self.black_pawns & mask) != 0) {
                    char = 'p';
                } else if ((self.black_knights & mask) != 0) {
                    char = 'n';
                } else if ((self.black_bishops & mask) != 0) {
                    char = 'b';
                } else if ((self.black_rooks & mask) != 0) {
                    char = 'r';
                } else if ((self.black_queens & mask) != 0) {
                    char = 'q';
                } else if ((self.black_king & mask) != 0) {
                    char = 'k';
                }

                std.debug.print(" {c} ", .{char});
            }
            std.debug.print("|\n", .{});
        }
        std.debug.print("  +------------------------+\n", .{});
        std.debug.print("    a  b  c  d  e  f  g  h\n\n", .{});
    }
};
