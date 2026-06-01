const std = @import("std");

const bitboard = @import("bitboard.zig");
const model_bytes align(@alignOf(f32)) = @embedFile("beyonder_nn.bin").*;

const model_floats = std.mem.bytesAsSlice(f32, &model_bytes);

const FC1_W_START: usize = 0;
const FC1_B_START: usize = FC1_W_START + (256 * 768);
const FC2_W_START: usize = FC1_B_START + 256;
const FC2_B_START: usize = FC2_W_START + (32 * 256);
const FC3_W_START: usize = FC2_B_START + 32;
const FC3_B_START: usize = FC3_W_START + 32;

fn addFeatures(l1: *[256]f32, bb: u64, piece_type: usize) void {
    var b = bb;
    while (b != 0) {
        const sq: usize = @intCast(@ctz(b));
        const feature_idx = piece_type * 64 + sq;
        
        for (0..256) |i| {
            const w_idx = FC1_W_START + (i * 768) + feature_idx;
            l1[i] += model_floats[w_idx];
        }
        b &= b - 1;
    }
}

pub fn evaluate(pos: *const bitboard.Position) i32 {
    var l1: [256]f32 = undefined;
    
    for (0..256) |i| {
        l1[i] = model_floats[FC1_B_START + i];
    }

    addFeatures(&l1, pos.white_pawns, 0);
    addFeatures(&l1, pos.white_knights, 1);
    addFeatures(&l1, pos.white_bishops, 2);
    addFeatures(&l1, pos.white_rooks, 3);
    addFeatures(&l1, pos.white_queens, 4);
    addFeatures(&l1, pos.white_king, 5);
    addFeatures(&l1, pos.black_pawns, 6);
    addFeatures(&l1, pos.black_knights, 7);
    addFeatures(&l1, pos.black_bishops, 8);
    addFeatures(&l1, pos.black_rooks, 9);
    addFeatures(&l1, pos.black_queens, 10);
    addFeatures(&l1, pos.black_king, 11);

    for (&l1) |*val| {
        if (val.* < 0.0) val.* = 0.0;
    }

    var l2: [32]f32 = undefined;
    for (0..32) |i| {
        l2[i] = model_floats[FC2_B_START + i];
        for (0..256) |j| {
            const w_idx = FC2_W_START + (i * 256) + j;
            l2[i] += model_floats[w_idx] * l1[j];
        }
    }

    for (&l2) |*val| {
        if (val.* < 0.0) val.* = 0.0;
    }

    var output = model_floats[FC3_B_START];
    for (0..32) |i| {
        output += model_floats[FC3_W_START + i] * l2[i];
    }

    const p = 1.0 / (1.0 + @exp(-output));

    var p_clamped = p;
    if (p_clamped < 0.001) p_clamped = 0.001; // Prevent ln(0) math explosions
    if (p_clamped > 0.999) p_clamped = 0.999;
    
    const cp_float = 290.68 * @log(p_clamped / (1.0 - p_clamped));
    const cp: i32 = @intFromFloat(cp_float);

    return if (pos.side_to_move) cp else -cp;
}
