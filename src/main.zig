const std = @import("std");
const datagen = @import("datagen.zig");

pub fn main(init: std.process.Init) !void {
    std.debug.print("========================================\n", .{});
    std.debug.print(" BEYONDER NEURAL NET DATA GENERATOR\n", .{});
    std.debug.print("========================================\n\n", .{});

    const num_games: usize = 1000;

    const io = init.io;
    const start = std.Io.Clock.now(.awake, io);

    try datagen.generateData(init.io, num_games);

    const end = std.Io.Clock.now(.awake, io);
    const elapsed = start.durationTo(end);
    const elapsed_s = @as(f64, @floatFromInt(elapsed.toNanoseconds())) / 1_000_000_000.0;
    
    std.debug.print("[*] Finished in {d:.2} seconds.\n", .{elapsed_s});
    std.debug.print("[*] Ready for Google Colab!\n", .{});
}   
