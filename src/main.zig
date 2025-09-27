const std = @import("std");
const buffalo = @import("buffalo");

pub fn main() !void {
    var reader: buffalo.Reader = try .init([1400]u8, "build.zig");
    var writer: buffalo.Writer = try .init([1400]u8, null);
    defer reader.file.close();
    _ = try reader.IO.stream(writer.IO, .unlimited);
    _ = try writer.IO.flush();
}
