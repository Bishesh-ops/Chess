const std = @import("std");
const bitboard = @import("bitboard.zig");
const search = @import("search.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;

    var pos = try bitboard.Position.loadFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1");
    pos.printBoard();

    var state = search.SearchState.init();
    const result = search.findBestMove(&pos, 6, &state);

    const src_f = @as(u8, result.best_move.source % 8);
    const src_r = @as(u8, result.best_move.source / 8);
    const tgt_f = @as(u8, result.best_move.target % 8);
    const tgt_r = @as(u8, result.best_move.target / 8);

    std.debug.print("Best move: {c}{c}{c}{c}  score: {}  nodes: {}\n", .{
        'a' + src_f, '1' + src_r,
        'a' + tgt_f, '1' + tgt_r,
        result.score,
        result.nodes,
    });
}
