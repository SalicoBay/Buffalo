//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const Writer = struct {
    buf: []u8,
    IO: *std.Io.Writer,

    inline fn init(buf: []u8) Writer {
        var outFile = std.fs.File.stdout();
        var host = outFile.writer(buf);
        return Writer{
            .buf = host.interface.buffer,
            .IO = &host.interface,
        };
    }

    inline fn initFileWriter(buf: []u8, filePath: []const u8) Writer {
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
    rider: Writer = undefined,
    fault: ?anyerror,

    pub inline fn init(buffer: []u8) Buffalo {
        var writer = Writer.init(buffer);
        return Buffalo{
            .rider = writer,
            .buffer = writer.buf,
            .fault = null,
        };
    }

    inline fn faulted(self: *Buffalo) bool {
        return (self.fault != null);
    }

    fn getFaultStatus(self: *Buffalo) !void {
        if (self.fault) |err| {
            return err;
        }
    }

    fn newFault(self: *Buffalo, err: anyerror) *Buffalo {
        if (self.faulted()) return self;
        self.fault = err;
        return self;
    }

    pub fn inspectBuffer(self: *Buffalo) *Buffalo {
        if (self.faulted()) return self;
        std.debug.print("{s}, {any}\n", .{ self.buffer, self.faulted() });
        return self;
    }

    pub fn pull(self: *Buffalo, str: []const u8) *Buffalo {
        if (self.faulted()) return self;
        if (str.len > (self.buffer.len - self.rider.IO.end)) {
            self.rider.IO.writeAll(str) catch |err| {
                return self.newFault(err);
            };
            return self;
        }
        var reader = std.Io.Reader.fixed(str);
        while (reader.readSliceShort(self.buffer[self.rider.IO.end..])) |bytesRead| {
            if (bytesRead == 0) break;
            self.rider.IO.end += bytesRead;
        } else |_| {}
        return self;
    }

    pub fn pullFromXToEnd(self: *Buffalo, count: usize, str: []const u8) *Buffalo {
        if (self.faulted()) return self;
        if (count < str.len - 1) {
            return self.pull(str[count..]);
        } else return self.pull(str);
    }

    pub fn pullLast(self: *Buffalo, count: usize, str: []const u8) *Buffalo {
        if (self.faulted()) return self;
        if ((count + 1) < str.len) {
            return self.pull(str[str.len - count .. str.len]);
        } else return self.pull(str);
    }

    pub fn pullFirst(self: *Buffalo, count: usize, str: []const u8) *Buffalo {
        if (self.faulted()) return self;
        if ((count + 1) < str.len) {
            return self.pull(str[0 .. count + 1]);
        } else return self.pull(str);
    }

    pub fn pullBetween(self: *Buffalo, l: usize, r: usize, str: []const u8) *Buffalo {
        if (self.faulted()) return self;
        if (l > r) {
            return self.pull(str[r..l]);
        }
        if (0 <= l and r <= str.len) {
            return self.pull(str[l..r]);
        } else return self.pull(str);
    }

    pub fn takeByte(self: *Buffalo, c: u8) *Buffalo {
        if (self.faulted()) return self;
        _ = self.rider.IO.writeByte(c) catch |err| {
            return self.newFault(err);
        };
        return self;
    }

    pub fn pullThenCopy(self: *Buffalo, cs: []const u8, rep: usize, sep: ?[]const u8) *Buffalo {
        if (self.faulted()) return self;
        if (rep > 0) {
            for (0..rep) |_| {
                for (cs) |c| {
                    _ = self.rider.IO.writeByte(c) catch 0;
                }
                if (sep) |s| {
                    _ = self.pull(s);
                }
            }
            return self;
        }
        for (cs[0 .. cs.len - 1]) |c| { // End loop one cycle early...
            _ = self.rider.IO.writeByte(c) catch 0;
        }
        return self.takeByte(cs[cs.len - 1]); // ...so we can retain interface fluency
    }

    pub fn flush(self: *Buffalo) *Buffalo {
        _ = self.rider.IO.flush();
        return self;
    }

    pub fn wait(self: *Buffalo) !void { //Terminate call chain NO flush
        if (self.faulted()) return self.fault;
    }

    pub fn rest(self: *Buffalo) !void { //Terminate call chain AND flush
        _ = self.rider.IO.flush() catch |err| {
            _ = self.newFault(err);
        };
        if (self.faulted()) return self.getFaultStatus();
    }
};
