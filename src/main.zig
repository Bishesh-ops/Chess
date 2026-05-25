const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const attacks = @import("attacks.zig");

pub fn main() !void {
    std.debug.print("Testing Slider Rays...\n\n", .{});

    bitboard.printBitboard(attacks.ray_N[27], "Rook Ray North from d4");
    bitboard.printBitboard(attacks.ray_NE[18], "Bishop Ray NE from c3");
}
