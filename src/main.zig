const std = @import("std");
const Buffalo = @import("buffalo");

pub fn main() !void {
    const buffalo: Buffalo.Buffalo = try .init([1_000_000]u8, "bigfile.txt");
    _ = try buffalo.writer.writeAll(buffalo.territory);
    _ = try buffalo.writer.defaultFlush();
}
