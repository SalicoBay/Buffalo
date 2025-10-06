const std = @import("std");
const Buffalo = @import("buffalo");

const gpa = std.heap.page_allocator;
var Arena: std.heap.ArenaAllocator = .init(gpa);
var RingAllocator = std.heap.stackFallback(1024 * 10, Arena.allocator());

pub fn main() !void {
    const ring = RingAllocator.get();

    var buffalo: Buffalo.Buffalo = .init(try ring.alloc(u8, 10)); // <-- Initial capacity of the buffalo

    try buffalo
        .pullThenCopy("Yahtzee! ", 100, "Yahtzee! ")
        .pullLast(13, "The quick brown fox jumped over the lazy dog!")
        // .inspect()
        .rest();
}
