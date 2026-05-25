const std = @import("std");
const bitboard = @import("bitboard.zig");
const perft = @import("perft.zig");

pub fn main(init: std.process.Init) !void {
    std.debug.print("Starting Beyonder Engine...\n\n", .{});

    var pos = bitboard.Position.initStart();
    pos.printBoard();
    const io = init.io;

    try perft.runPerft(&pos, 5, io);
}
