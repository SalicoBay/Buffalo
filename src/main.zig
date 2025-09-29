const std = @import("std");
const Buffalo = @import("buffalo");

pub fn main() !void {
    var buffalo: Buffalo.Buffalo = try .init(48);
    var strB = "World!".*;

    _ = buffalo.read("Hello, ").read(&strB).write();
    buffalo.flush();
}
