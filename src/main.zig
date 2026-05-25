const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");

pub fn main() !void {
    std.debug.print("Starting Beyonder Engine...\n", .{});

    var pos = bitboard.Position.initStart();
    std.debug.print("\n--- INITIAL BOARD ---\n", .{});
    pos.printBoard();

    const e4 = movegen.Move{
        .source = 12,
        .target = 28,
        .flags = @intFromEnum(movegen.MoveFlag.double_pawn_push),
    };

    var next_pos = pos;

    const is_legal = movegen.makeMove(&next_pos, e4);

    if (is_legal) {
        std.debug.print("\n--- AFTER PLAYING e2-e4 ---\n", .{});
        next_pos.printBoard();

        std.debug.print("Is it White's turn? {}\n", .{next_pos.side_to_move});
        if (next_pos.en_passant_sq) |ep| {
            std.debug.print("En Passant Target Square active at index: {}\n", .{@intFromEnum(ep)});
        }
    } else {
        std.debug.print("Move was illegal!\n", .{});
    }
}
