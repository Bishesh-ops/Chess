const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const search = @import("search.zig");

fn printMoveStr(move: movegen.Move) void {
    const f_src = @as(u8, @intCast(move.source % 8));
    const r_src = @as(u8, @intCast(move.source / 8));
    const f_tgt = @as(u8, @intCast(move.target % 8));
    const r_tgt = @as(u8, @intCast(move.target / 8));
    std.debug.print("{c}{c}{c}{c}", .{ 'a' + f_src, '1' + r_src, 'a' + f_tgt, '1' + r_tgt });
}

pub fn main() !void {
    std.debug.print("Beyonder AI is online...\n\n", .{});

    var pos = bitboard.Position.initStart();
    const search_depth: u8 = 4;

    for (0..10) |half_move| {
        std.debug.print("--- Move {} ({s}) ---\n", .{ 
            (half_move / 2) + 1, 
            if (pos.side_to_move) "White" else "Black" 
        });
        
        pos.printBoard();

        std.debug.print("Thinking...\n", .{});
        
        const best_move = search.findBestMove(&pos, search_depth);
        
        std.debug.print("Beyonder plays: ", .{});
        printMoveStr(best_move);
        std.debug.print("\n\n", .{});

        _ = movegen.makeMove(&pos, best_move);
    }
    
    std.debug.print("--- Final Position ---\n", .{});
    pos.printBoard();
}
