const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const search = @import("search.zig");

pub fn main() !void {
    var threaded_io: std.Io.Threaded = .init_single_threaded;
    const io = threaded_io.io();
    defer threaded_io.deinit();

    std.debug.print("========================================\n", .{});
    std.debug.print(" BEYONDER NEURAL ENGINE ONLINE\n", .{});
    std.debug.print("========================================\n\n", .{});

    var pos = bitboard.Position.initStart();
    var state = search.SearchState.init();

    const search_depth: u8 = 5;

    for (0..12) |half_move| {
        std.debug.print("--- Move {} ({s}) ---\n", .{
            (half_move / 2) + 1,
            if (pos.side_to_move) "White" else "Black",
        });

        pos.printBoard();

        std.debug.print("Thinking (Depth {})...\n", .{search_depth});

        const start = std.Io.Clock.now(.awake, io);
        const result = search.findBestMove(&pos, search_depth, &state);
        const end = std.Io.Clock.now(.awake, io);

        const duration = start.durationTo(end);
        const elapsed_ms = @as(f64, @floatFromInt(duration.toNanoseconds())) / 1_000_000.0;
        
        const nps = if (elapsed_ms > 0.0) 
            @as(f64, @floatFromInt(result.nodes)) / (elapsed_ms / 1000.0) 
        else 
            0.0;

        const src_f = @as(u8, @intCast(result.best_move.source % 8));
        const src_r = @as(u8, @intCast(result.best_move.source / 8));
        const tgt_f = @as(u8, @intCast(result.best_move.target % 8));
        const tgt_r = @as(u8, @intCast(result.best_move.target / 8));

        std.debug.print("Beyonder plays: {c}{c}{c}{c}\n", .{ 'a' + src_f, '1' + src_r, 'a' + tgt_f, '1' + tgt_r });
        std.debug.print("Eval: {} cp | Nodes: {} | Time: {d:.2} ms | NPS: {d:.0}\n\n", .{
            result.score,
            result.nodes,
            elapsed_ms,
            nps,
        });

        _ = movegen.makeMove(&pos, result.best_move);
    }

    std.debug.print("--- Final Position ---\n", .{});
    pos.printBoard();
}  
