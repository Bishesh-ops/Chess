const std = @import("std");
const datagen = @import("datagen.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;
    std.debug.print("Starting Beyonder Data Generation Pipeline...\n\n", .{});

    try datagen.generateData(5);
}
