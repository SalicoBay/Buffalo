//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const Reader = struct {
    buf: []u8,
    IO: *std.Io.Reader,
    inline fn init(str: []const u8) Reader {
        var host = std.Io.Reader.fixed(str);
        return Reader{
            .buf = host.buffer,
            .IO = &host,
        };
    }
};

const Writer = struct {
    buf: []u8,
    IO: *std.Io.Writer,

    inline fn init(comptime bufType: type, buf: *bufType) Writer {
        var outFile = std.fs.File.stdout();
        var host = outFile.writer(buf);
        return Writer{
            .buf = host.interface.buffer,
            .IO = &host.interface,
        };
    }

    inline fn initFileWriter(comptime bufType: type, buf: *bufType, filePath: []const u8) Writer {
        var outFile = std.fs.cwd().createFile(filePath, .{}) catch {};
        var host = outFile.writer(buf);
        return Writer{
            .buf = host.interface.buffer,
            .IO = &host.interface,
        };
    }
};

pub const Buffalo = struct {
    buffer: []u8 = undefined,
    count: usize = 0,
    rider: *Writer = undefined,

    pub inline fn init(comptime size: usize) Buffalo {
        var wBuf: [size]u8 = undefined;
        var swapBuf: [size]u8 = undefined;
        var writer = Writer.init(@TypeOf(wBuf), &wBuf);
        return Buffalo{
            .rider = &writer,
            .buffer = &swapBuf,
        };
    }

    pub fn packThis(self: *Buffalo, str: []const u8, a: std.mem.Allocator) *Buffalo {
        if (str.len > self.buffer.len) { // Total buffalo capacity is buffalo.pack.len * 2
            return self.newPack(str.len * 2, a).pack(str);
        }
        return self.pack(str);
    }

    pub fn packFirst(self: *Buffalo, size: usize, str: []const u8) *Buffalo {
        if (size > self.buffer.len) { // Total buffalo capacity is buffalo.pack.len * 2
            return self.pack(str[0..self.buffer.len]);
        }
        return self.pack(str[0..size]);
    }

    fn pack(self: *Buffalo, str: []const u8) *Buffalo {
        self.count += str.len;
        std.debug.assert(self.buffer.len >= str.len);
        @memcpy(self.buffer, str);
        return self;
    }

    pub fn consumePack(self: *Buffalo) *Buffalo {
        defer self.count = 0;
        return self.consumeThis(self.buffer[0..self.count]);
    }

    pub fn consumePackPlus(self: *Buffalo, cs: []const u8) *Buffalo {
        defer self.count = 0;
        return self.consumeThis(self.buffer[0..self.count]).consumeBytes(cs);
    }

    pub fn consumeThis(self: *Buffalo, str: []const u8) *Buffalo {
        if (str.len > self.buffer.len * 2) { // Total buffalo capacity is buffalo.pack.len * 2
            self.rider.IO.writeAll(str) catch {};
            return self;
        }
        var reader: Reader = .init(str);
        while (reader.IO.readSliceShort(self.buffer)) |bytesRead| {
            if (bytesRead == 0) break;
            if (bytesRead < self.buffer.len and bytesRead > 0) {
                _ = self.tinyPush(bytesRead);
                break;
            }
            _ = self.push();
        } else |_| {}
        return self;
    }

    pub fn consumeFirst(self: *Buffalo, count: usize, str: []const u8) *Buffalo {
        if (count < str.len) {
            return self.consumeThis(str[0..count]);
        } else return self.consumeThis(str);
    }

    pub fn consumeByte(self: *Buffalo, c: u8) *Buffalo {
        _ = self.rider.IO.writeByte(c) catch 0;
        return self;
    }

    pub fn consumeBytes(self: *Buffalo, c: []const u8) *Buffalo {
        for (c) |codepoint| {
            _ = self.rider.IO.writeByte(codepoint) catch 0;
        }
        return self;
    }

    pub fn consumeBytesXTimes(self: *Buffalo, cs: []const u8, rep: usize) *Buffalo {
        if (rep > 0) {
            for (0..rep) |_| {
                for (cs) |c| {
                    _ = self.rider.IO.writeByte(c) catch 0;
                }
            }
            return self;
        }
        for (cs[0 .. cs.len - 1]) |c| {
            _ = self.rider.IO.writeByte(c) catch 0;
        }
        return self.consumeByte(cs[cs.len - 1]);
    }

    pub fn inspect(self: *Buffalo) *Buffalo {
        std.debug.print("---------------<Inspection>---------------\n\n", .{});
        std.debug.print("Buffalo: start::[`{s}`]::end\n", .{self.buffer[0..self.count]});
        std.debug.print("\n", .{});
        std.debug.print("Rider: start::[`{s}`]::end\n", .{self.rider.buf});
        std.debug.print("\n---------------</Inspection>---------------\n\n", .{});
        return self;
    }

    pub fn rest(self: *Buffalo) void {
        _ = self;
    }

    pub fn newPack(self: *Buffalo, size: usize, packer: std.mem.Allocator) *Buffalo {
        self.buffer = packer.alloc(u8, @divFloor(size, 2)) catch undefined;
        self.rider.buf = packer.alloc(u8, @divFloor(size, 2)) catch undefined;
        self.rider.IO.end = 0;
        return self;
    }

    pub fn dropOff(self: *Buffalo) *Buffalo {
        _ = self.rider.IO.flush() catch {};
        @memset(self.buffer.ptr[0..self.buffer.len], ' ');
        @memset(self.rider.IO.buffer, ' ');
        return self;
    }

    fn tinyPush(self: *Buffalo, offset: usize) *Buffalo {
        _ = self.rider.IO.write(self.buffer[0..offset]) catch 0;
        return self;
    }

    fn push(self: *Buffalo) *Buffalo {
        _ = self.rider.IO.write(self.buffer) catch 0;
        return self;
    }
};
