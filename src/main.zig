const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
fn printSquare(sq: u6) void {
    const file = @as(u8, @intCast(sq % 8));
    const rank = @as(u8, @intCast(sq / 8));
    std.debug.print("{c}{c}", .{ 'a' + file, '1' + rank });
}

fn printMove(move: movegen.Move) void {
    printSquare(move.source);
    printSquare(move.target);

    if (move.flags >= @intFromEnum(movegen.MoveFlag.promotion_knight) and
        move.flags <= @intFromEnum(movegen.MoveFlag.promotion_queen))
    {
        std.debug.print(" (Promo)", .{});
    }
}

pub fn main() !void {
    std.debug.print("Starting Beyonder Engine...\n", .{});

    var pos = bitboard.Position.initStart();
    pos.printBoard();

    var list = movegen.MoveList{};

    movegen.generateMoves(&pos, &list);

    std.debug.print("Generated {} pseudo-legal moves:\n", .{list.count});
    std.debug.print("--------------------------------\n", .{});

    for (list.moves[0..list.count], 0..) |move, i| {
        std.debug.print("{d:0>2}. ", .{i + 1});
        printMove(move);
        std.debug.print("  [Flag: {}]\n", .{move.flags});
    }
    std.debug.print("\n", .{});
}
