const std = @import("std");
const Buffalo = @import("buffalo");

pub fn main() !void {
    var buffalo: Buffalo.Buffalo = try .init([8_400]u8, "build.zig", null);
    // _ = try buffalo.reader.stream(buffalo.writer, .unlimited);
    _ = try buffalo.writer.writeAll(buffalo.territory);
    _ = try buffalo.writer.defaultFlush();
}
