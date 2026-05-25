const std = @import("std");
const bitboard = @import("bitboard.zig");
const Bitboard = bitboard.Bitboard;

fn initRay(comptime dx: i8, comptime dy: i8) [64]Bitboard {
    var rays: [64]Bitboard = undefined;

    for (0..64) |sq| {
        var ray: Bitboard = 0;

        var x: i8 = @intCast(sq % 8);
        var y: i8 = @intCast(sq / 8);

        while (true) {
            x += dx;
            y += dy;

            if (x < 0 or x > 7 or y < 0 or y > 7) break;

            const target_sq = @as(u6, @intCast(y * 8 + x));
            ray |= (@as(u64, 1) << target_sq);
        }
        rays[sq] = ray;
    }

    return rays;
}

// Rook Directions
pub const ray_N = initRay(0, 1); // North: x+0, y+1
pub const ray_S = initRay(0, -1); // South: x+0, y-1
pub const ray_E = initRay(1, 0); // East:  x+1, y+0
pub const ray_W = initRay(-1, 0); // West:  x-1, y+0

// Bishop Directions
pub const ray_NE = initRay(1, 1); // NorthEast: x+1, y+1
pub const ray_NW = initRay(-1, 1); // NorthWest: x-1, y+1
pub const ray_SE = initRay(1, -1); // SouthEast: x+1, y-1
pub const ray_SW = initRay(-1, -1); // SouthWest: x-1, y-1
