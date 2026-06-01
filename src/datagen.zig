const std = @import("std");
const bitboard = @import("bitboard.zig");
const movegen = @import("movegen.zig");
const search = @import("search.zig");
const evaluate = @import("evaluate.zig");
const attacks = @import("attacks.zig");

const DataPoint = struct {
    fen: [100]u8,
    fen_len: usize,
    eval: i32,
    is_white_turn: bool,
};

pub fn generateData(io: std.Io, num_games: usize) !void {
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.createFile(io, "training_data.csv", .{});
    defer file.close(io);

    var write_buf: [4096]u8 = undefined;
    var fw = file.writer(io, &write_buf);
    const writer = &fw.interface;

    try writer.print("FEN,Evaluation,Result\n", .{});

    const rng_impl: std.Random.IoSource = .{ .io = io };
    const secure_rand = rng_impl.interface();
    var seed: u64 = undefined;
    secure_rand.bytes(std.mem.asBytes(&seed));

    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    std.debug.print("Generating {} games of self-play data...\n", .{num_games});

    for (0..num_games) |game_idx| {
        var pos = bitboard.Position.initStart();
        var game_history: [500]DataPoint = undefined;
        var ply_count: usize = 0;

        for (0..4) |_| {
            var list = movegen.MoveList{};
            movegen.generateMoves(&pos, &list);

            var legal_moves: [256]movegen.Move = undefined;
            var legal_count: usize = 0;

            for (list.moves[0..list.count]) |move| {
                var test_pos = pos;
                if (movegen.makeMove(&test_pos, move)) {
                    legal_moves[legal_count] = move;
                    legal_count += 1;
                }
            }

            if (legal_count > 0) {
                const idx = random.intRangeLessThan(usize, 0, legal_count);
                _ = movegen.makeMove(&pos, legal_moves[idx]);
            }
        }

        var game_result: f32 = 0.5;
        var is_game_over = false;

        while (ply_count < 200 and !is_game_over) {
            var fen_buf: [100]u8 = undefined;
            const fen_str = try pos.toFen(&fen_buf);

            game_history[ply_count] = DataPoint{
                .fen = fen_buf,
                .fen_len = fen_str.len,
                .eval = evaluate.evaluate(&pos),
                .is_white_turn = pos.side_to_move,
            };

            const best_move = search.findBestMove(&pos, 3);

            var list = movegen.MoveList{};
            movegen.generateMoves(&pos, &list);
            var has_legal = false;
            for (list.moves[0..list.count]) |m| {
                var test_pos = pos;
                if (movegen.makeMove(&test_pos, m)) {
                    has_legal = true;
                    break;
                }
            }

            if (!has_legal) {
                const is_white = pos.side_to_move;
                const king_sq: u6 = @intCast(@ctz(if (is_white) pos.white_king else pos.black_king));
                const in_check = attacks.isSquareAttacked(&pos, king_sq, !is_white);
                game_result = if (in_check) (if (is_white) 0.0 else 1.0) else 0.5;
                is_game_over = true;
                break;
            }

            _ = movegen.makeMove(&pos, best_move);
            ply_count += 1;
        }

        for (0..ply_count) |i| {
            const data = game_history[i];
            const absolute_eval = if (data.is_white_turn) data.eval else -data.eval;
            try writer.print("{s},{},{d:.1}\n", .{
                data.fen[0..data.fen_len],
                absolute_eval,
                game_result,
            });
        }

        std.debug.print("Game {} complete (Plies: {}, Result: {d:.1})\n", .{ game_idx + 1, ply_count, game_result });
    }

    try writer.flush();
    std.debug.print("\nDataset successfully written to training_data.csv\n", .{});
}
