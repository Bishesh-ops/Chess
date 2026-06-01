const std = @import("std");
const movegen = @import("movegen.zig");

pub const Bound = enum(u2) {
    exact,
    lower, 
    upper,
};

pub const TTEntry = struct {
    key: u64 = 0,
    move: movegen.Move = .{ .source = 0, .target = 0, .flags = 0 },
    score: i32 = 0,
    depth: u8 = 0,
    bound: Bound = .exact,
};

const TT_SIZE: usize = 1 << 20;
const TT_MASK: usize = TT_SIZE - 1;

pub const TranspositionTable = struct {
    entries: [TT_SIZE]TTEntry = [_]TTEntry{.{}} ** TT_SIZE,

    pub fn probe(self: *const TranspositionTable, key: u64) ?TTEntry {
        const entry = self.entries[key & TT_MASK];
        if (entry.key == key and entry.depth != 0) return entry;
        return null;
    }

    pub fn store(self: *TranspositionTable, key: u64, move: movegen.Move, score: i32, depth: u8, bound: Bound) void {
        const idx = key & TT_MASK;
        const existing = &self.entries[idx];
        if (existing.key != key or depth >= existing.depth) {
            self.entries[idx] = .{
                .key = key,
                .move = move,
                .score = score,
                .depth = depth,
                .bound = bound,
            };
        }
    }

    pub fn clear(self: *TranspositionTable) void {
        @memset(&self.entries, TTEntry{});
    }
};
