//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const Reader = struct {
    buf: []u8,
    IO: *std.Io.Reader,
    inline fn init(comptime bufType: type, buf: bufType) !Reader {
        var host = std.Io.Reader.fixed(buf);
        var new = Reader{
            .buf = host.buffer,
            .IO = &host,
        };
        _ = &new;
        return new;
    }
    pub fn clear(self: *Reader) void {
        @memset(self.buf, ' ');
    }
};

pub const Writer = struct {
    buf: []u8,
    IO: *std.Io.Writer,

    inline fn init(comptime bufType: type, buf: bufType) Writer {
        var outFile = std.fs.File.stdout();
        var host = outFile.writer(buf);
        var new = Writer{
            .buf = host.interface.buffer,
            .IO = &host.interface,
        };
        _ = &new;
        return new;
    }
};

pub const Buffalo = struct {
    block: []u8 = undefined,
    boundary: usize = undefined,
    reader: *Reader = undefined,
    writer: *Writer = undefined,

    pub inline fn init(comptime size: usize) !Buffalo {
        var buf: [size]u8 = @splat(undefined);
        const front = @TypeOf(buf[0 .. size / 2]);
        const back = @TypeOf(buf[size / 2 .. size]);
        var reader = try Reader.init(front, buf[0 .. size / 2]);
        var writer = Writer.init(back, buf[size / 2 .. size]);

        var new = Buffalo{
            .block = &buf,
            .boundary = buf.len / 2,
            .reader = &reader,
            .writer = &writer,
        };

        _ = &new;
        return new;
    }

    pub fn read(self: *Buffalo, str: []const u8) *Buffalo {
        for (str, 0..) |c, i| {
            self.reader.buf[i] = c;
            self.reader.IO.seek += 1;
        }
        @memmove(self.writer.buf[self.writer.IO.end..self.writer.buf.len], self.reader.buf[0..self.reader.IO.seek]);
        self.reader.clear();
        self.writer.IO.end += self.reader.IO.seek;
        return self;
    }

    pub fn write(self: *Buffalo) *Buffalo {
        _ = self.writer.IO.write(self.writer.buf[0..self.writer.IO.end]) catch 0;
        self.reader.IO.seek = 0;
        return self;
    }

    pub fn print(self: *Buffalo, lbl: ?[]const u8) *Buffalo {
        if (lbl) |l| {
            self.writer.IO.print("{s}:{s}", .{ l, self.writer.buf }) catch {};
        } else {
            self.writer.IO.print("Anon_Print: {s}", .{self.writer.buf}) catch {};
        }
        return self;
    }

    pub fn flush(self: *Buffalo) void {
        self.writer.IO.flush() catch {};
    }
};
