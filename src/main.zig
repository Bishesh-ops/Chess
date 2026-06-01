const std = @import("std");
const bitboard = @import("bitboard.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;
    std.debug.print("Testing FEN Engine...\n\n", .{});

    const kiwipete_fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";
    
    var pos = try bitboard.Position.loadFen(kiwipete_fen);
    
    std.debug.print("Successfully loaded Kiwipete!\n", .{});
    pos.printBoard();

    var fen_buffer: [100]u8 = undefined;
    const exported_fen = try pos.toFen(&fen_buffer);

    std.debug.print("Original FEN: {s}\n", .{kiwipete_fen});
    std.debug.print("Exported FEN: {s}\n", .{exported_fen});

    if (std.mem.eql(u8, kiwipete_fen, exported_fen)) {
        std.debug.print("\nSUCCESS: FEN Round-Trip is perfect.\n", .{});
    } else {
        std.debug.print("\nERROR: FEN strings do not match.\n", .{});
    }
}
