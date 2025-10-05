const std = @import("std");
const Buffalo = @import("buffalo");

pub fn main() !void {
    // Simple convenience wrapper around Std.Io.Reader/Writers. Instantiates as [size]u8 buffer.
    // No allocator is needed for the init, as we construct via inline semantics. DO NOT PANIC
    // No other member functions will *ever* allocate additional memory through inline semantics.
    // Any member function that accepts a [~]const u8 will implicitly instantiate a stack-local
    // std.Io.reader.fixed() whose lifetime will naturally end *before* the method return completes.

    var buffalo: Buffalo.Buffalo = .init(3_000_000); // <-- Initial capacity of the buffalo

    try buffalo
        .pullXTimes("Yahtzee! ", 3_000, "Yahtzee! ")
        .wait();

    try buffalo
        .rest();
}
