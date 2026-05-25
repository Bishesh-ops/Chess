const std = @import("std");
const movegen = @import("movegen.zig");
const bitboard = @import("bitboard.zig");

pub fn main() !void {
    std.debug.print("Starting Beyonder Chess Engine...\n\n", .{});

    std.debug.print("Size of Move struct: {} bytes\n", .{@sizeOf(movegen.Move)});
    std.debug.print("Size of MoveList array: {} bytes\n\n", .{@sizeOf(movegen.MoveList)});

    const e2_e4 = movegen.Move{
        .source = 12,
        .target = 28,
        .flags = @intFromEnum(movegen.MoveFlag.quiet),
    };

    const raw_u16: u16 = @bitCast(e2_e4);
    std.debug.print("Move e2-e4 packed as integer: {}\n", .{raw_u16});
    const pos = bitboard.Position.initStart();

    pos.printBoard();
}
