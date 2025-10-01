const std = @import("std");
const Buffalo = @import("buffalo");

var mem_buffer_1: [1000]u8 = undefined;
var Allocator: std.heap.FixedBufferAllocator = .init(&mem_buffer_1);
var a = Allocator.allocator();

pub fn main() !void {
    // Simple convenience wrapper around Std.Io.Reader/Writers. Instantiates 2 :: [size % 2]u8 buffers.
    // No allocator is needed for the init, as we construct via inline semantics. DO NOT PANIC
    // No other member functions will *ever* allocate additional memory through inline semantics.
    // Any member function that accepts a [~]const u8 will implicitly instantiate a stack-local
    // std.Io.reader.fixed() whose lifetime will naturally end *before* the method return completes.

    var buffalo: Buffalo.Buffalo = .init(100); // <-- Initial capacity of the buffalo

    buffalo
        .packFirst(20, "I wanna be the very best, like no one ever was")
        .inspect()
        .consumePackPlus(" \n\n")
        .dropOff()
        .consumeFirst(20, "I wanna be the very best, like no one ever was")
        .inspect()
        .consumeBytesXTimes("\n", 1)
        .dropOff()
        .rest();
}

// .consume("The quick brown fox jumped over the lazy dog!") //Have the Buffalo 'eat' the entire string
// //   This can potentially be an IO event if the string's length is sufficiently large as to exceed
// //   the capacity of the Buffalo's component buffers.
// .dropOff() // Have the Buffalo pass whatever it's carrying to Io. Zero out state
// //
// .consumeFirst(32, "The quick brown fox jumped over the lazy dog!") // 'Eat' the first x bytes of the string
// //
// .dropOff() // All reads are done with a temporary, fixed reader using the Buffalo's buffer as dest
// //
// .newPack(100, a) // Discard current state, accept new backing buffers.
// //
// .consumeBytesXTimes("\n", 3) //Trying to pull bytes > str.len, will cause Buffalo to drain the entire str
// //
// .consumeFirst(1200, "The quick brown fox jumped over the lazy dog!") // Using a fixed buffer allocator works
// //                                                                   well here. It's basically a ring
// //                                                                   buffer for our ring buffer!
// .dropOff() // There's nothing to pass to IO, but internal state is zero'd implicitely.
// .rest(); // NoOp call chain terminator
