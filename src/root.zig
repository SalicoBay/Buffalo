//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub const Reader = struct {
    file: std.fs.File,
    buf: []u8,
    IO: *std.Io.Reader,

    pub inline fn init(comptime sizedType: type, comptime filePath: ?[]const u8) !Reader {
        var file = switch (filePath == null) {
            true => try std.fs.File.stdin(),
            false => try std.fs.cwd().openFile(filePath.?, .{}),
        };
        var buf: sizedType = undefined;
        var host_reader = file.reader(&buf);
        var new = Reader{
            .file = file,
            .buf = &buf,
            .IO = &host_reader.interface,
        };
        _ = &new;
        return new;
    }
};

pub const Writer = struct {
    file: std.fs.File,
    buf: []u8,
    IO: *std.Io.Writer,

    pub inline fn init(comptime sizedType: type, comptime filePath: ?[]const u8) !Writer {
        var file = switch (filePath == null) {
            true => std.fs.File.stdout(),
            false => try std.fs.cwd().openFile(filePath.?, .{}),
        };
        var buf: sizedType = undefined;
        var host_writer = file.writer(&buf);
        var new = Writer{
            .file = file,
            .buf = &buf,
            .IO = &host_writer.interface,
        };
        _ = &new;
        return new;
    }
};
