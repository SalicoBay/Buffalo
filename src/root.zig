//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const Reader = struct {
    buf: []u8,
    IO: *std.Io.Reader,
    inline fn init(comptime filePath: ?[]const u8) !Reader {
        var host = &std.Io.Reader.fixed(@embedFile(filePath.?));

        var new = Reader{
            .buf = host.buffer,
            .IO = @constCast(host),
        };
        _, _ = .{ &new, &host }; // We want vars, but don't mutate in scope, therefore...
        return new;
    }
};

pub const Writer = struct {
    buf: []u8,
    IO: *std.Io.Writer,

    inline fn init(comptime sizedType: type) !Writer {
        var buf: sizedType = undefined;
        var outFile = try std.fs.cwd().createFile("./out.txt", .{});
        var host = outFile.writer(&buf);
        var new = Writer{
            .buf = &buf,
            .IO = &host.interface,
        };
        _, _ = .{ &new, &host };
        return new;
    }
};

pub const Buffalo = struct {
    territory: []const u8,
    in: []u8,
    out: []u8 = undefined,
    reader: *std.Io.Reader = undefined,
    writer: *std.Io.Writer = undefined,

    pub inline fn init(comptime sizedType: type, comptime readTarget: ?[]const u8) !Buffalo {
        const reader = try Reader.init(readTarget);
        const writer = try Writer.init(sizedType);
        var new_read_buf = reader.buf;
        var new_write_buf = writer.buf;

        var new = Buffalo{
            .territory = reader.IO.buffer,
            .in = new_read_buf,
            .out = new_write_buf,
            .reader = reader.IO,
            .writer = writer.IO,
        };

        _, _, _ = .{ &new, &new_read_buf, &new_write_buf };
        return new;
    }
};
