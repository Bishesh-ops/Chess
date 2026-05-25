const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");

fn printMove(move: movegen.Move) void {
    const f_src = @as(u8, @intCast(move.source % 8));
    const r_src = @as(u8, @intCast(move.source / 8));
    const f_tgt = @as(u8, @intCast(move.target % 8));
    const r_tgt = @as(u8, @intCast(move.target / 8));

    std.debug.print("{c}{c}{c}{c}", .{
        'a' + f_src, '1' + r_src,
        'a' + f_tgt, '1' + r_tgt,
    });

    if (move.flags == @intFromEnum(movegen.MoveFlag.promotion_queen)) {
        std.debug.print("q", .{});
    } else if (move.flags == @intFromEnum(movegen.MoveFlag.promotion_rook)) {
        std.debug.print("r", .{});
    } else if (move.flags == @intFromEnum(movegen.MoveFlag.promotion_bishop)) {
        std.debug.print("b", .{});
    } else if (move.flags == @intFromEnum(movegen.MoveFlag.promotion_knight)) {
        std.debug.print("n", .{});
    }
}

fn perft(pos: *bitboard.Position, depth: u8) u64 {
    if (depth == 0) return 1;

    var nodes: u64 = 0;
    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    for (list.moves[0..list.count]) |move| {
        var next_pos = pos.*;
        if (movegen.makeMove(&next_pos, move)) {
            nodes += perft(&next_pos, depth - 1);
        }
    }
    return nodes;
}

pub fn runPerft(pos: *bitboard.Position, depth: u8, io: std.Io) !void {
    std.debug.print("Performance Test (Depth {})\n", .{depth});
    std.debug.print("--------------------------------\n", .{});

    const start_time = std.Io.Clock.awake.now(io);

    var total_nodes: u64 = 0;
    var list = movegen.MoveList{};
    movegen.generateMoves(pos, &list);

    for (list.moves[0..list.count]) |move| {
        var next_pos = pos.*;
        if (movegen.makeMove(&next_pos, move)) {
            const nodes = perft(&next_pos, depth - 1);
            printMove(move);
            std.debug.print(": {}\n", .{nodes});
            total_nodes += nodes;
        }
    }

    const duration = start_time.untilNow(io, .awake);

    const elapsed_ns: f64 = @floatFromInt(duration.nanoseconds);
    const elapsed_ms = elapsed_ns / 1_000_000.0;
    const elapsed_seconds = elapsed_ms / 1000.0;

    const nps = @as(f64, @floatFromInt(total_nodes)) / elapsed_seconds;

    std.debug.print("--------------------------------\n", .{});
    std.debug.print("Total Nodes: {}\n", .{total_nodes});
    std.debug.print("Time Taken: {d:.2} ms\n", .{elapsed_ms});
    std.debug.print("Speed (NPS): {d:.0} nodes/sec\n", .{nps});
}
