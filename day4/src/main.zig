const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const ReadEnum = enum {
    None,
    X,
    M,
    A,
    S,
};

const StateRead = struct {
    state: ReadEnum,

    pub fn readChar(self: *StateRead, char: u8) bool {
        switch (self.state) {
            ReadEnum.None => if (char == 'X') self.state == ReadEnum.X,
            ReadEnum.X => if (char == 'M') self.state == ReadEnum.M,
            ReadEnum.M => if (char == 'A') self.state == ReadEnum.A,
            ReadEnum.A => if (char == 'S') self.state == ReadEnum.S,
            ReadEnum.S => {
                return true;
            },
        }

        return false;
    }
};

pub fn tryReadWord(level: usize) bool {
    if (level > 3) return false;

    _ = tryReadWord(level + 1);
    std.debug.print("{d}\n", .{level});
    // Up Left
    // Up Middle
    // Up Right
    // Right
    // Left
    // Bottom Left
    // Bottom Middle
    // Bottom Right

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("test.txt", .{});
    // const file = std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    var readerStream = bufReader.reader();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    var lineLen: usize = undefined;

    var buf: [1024]u8 = undefined;
    while (try readerStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        lineLen = line.len;
        try list.appendSlice(line);
    }

    std.debug.print("{d}\n", .{list.items.len});
    _ = tryReadWord(0);

    try bw.flush();
}
