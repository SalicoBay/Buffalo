//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const Reader = struct {
    buf: []u8,
    IO: *std.Io.Reader,
    inline fn init(comptime sizedType: type, comptime filePath: ?[]const u8) !Reader {
        var buf: sizedType = undefined;
        var host = &std.Io.Reader.fixed(@embedFile(filePath.?));

        var new = Reader{
            .buf = &buf,
            .IO = @constCast(host),
        };
        _, _ = .{ &new, &host }; // We want vars, but don't mutate in scope, therefore...
        return new;
    }
};

pub const Writer = struct {
    buf: []u8,
    IO: *std.Io.Writer,

    inline fn init(comptime sizedType: type, comptime filePath: ?[]const u8) !Writer {
        var buf: sizedType = undefined;
        var host = switch (filePath == null) {
            true => @constCast(&std.fs.File.stdout().writer(&buf).interface),
            false => std.Io.Writer.fixed(@embedFile(filePath.?)),
        };
        var new = Writer{
            .buf = &buf,
            .IO = host,
        };
        _, _ = .{ &new, &host };
        return new;
    }
};

pub const Buffalo = struct {
    territory: []const u8,
    streams: struct {
        in: []u8,
        out: []u8,
    } = undefined,
    reader: *std.Io.Reader = undefined,
    writer: *std.Io.Writer = undefined,

    pub inline fn init(comptime sizedType: type, comptime readTarget: ?[]const u8, comptime writeTarget: ?[]const u8) !Buffalo {
        var reader = try Reader.init(sizedType, readTarget);
        var writer = try Writer.init(sizedType, writeTarget);

        var new_read_buf = reader.buf;
        var new_write_buf = writer.buf;

        _, _ = .{ &new_read_buf, &new_write_buf };

        var new = Buffalo{
            .territory = reader.IO.buffer,
            .streams = .{
                .in = new_read_buf,
                .out = new_write_buf,
            },
            .reader = reader.IO,
            .writer = writer.IO,
        };
        _ = &new;
        return new;
    }
};
