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

    pub fn getNext(self: ReadEnum) ReadEnum {
        return switch (self) {
            ReadEnum.None => ReadEnum.X,
            ReadEnum.X => ReadEnum.M,
            ReadEnum.M => ReadEnum.A,
            ReadEnum.A => ReadEnum.S,
            ReadEnum.S => ReadEnum.None,
        };
    }

    // Bitwise Flags
    // 00 - Format
    // 01 - Valid for next
    // 11 - Valid and complete
    pub fn validForNextEnum(self: ReadEnum, input: u8) u8 {
        return switch (self) {
            ReadEnum.None => if (input == 'X') 0b01 else 0b00,
            ReadEnum.X => if (input == 'M') 0b01 else 0b00,
            ReadEnum.M => if (input == 'A') 0b01 else 0b00,
            ReadEnum.A => if (input == 'S') 0b11 else 0b00,
            ReadEnum.S => 0b00,
        };
    }
};

// const StateRead = struct {
//     state: ReadEnum,
//     tries: u8,
//
//     pub fn readChar(self: *StateRead, char: u8) bool {
//         switch (self.state) {
//             ReadEnum.None => if (char == 'X') self.state == ReadEnum.X,
//             ReadEnum.X => if (char == 'M') self.state == ReadEnum.M,
//             ReadEnum.M => if (char == 'A') self.state == ReadEnum.A,
//             ReadEnum.A => if (char == 'S') self.state == ReadEnum.S,
//             ReadEnum.S => {
//                 return true;
//             },
//         }
//
//         return false;
//     }
// };

// fn test read
// input: ReadEnum
// input: pos
// if pos == validNext WHERE validNext == S
// if pos != validNext for ReadEnum || pos out of range return (return false?)
// define out bool
//
// NOTE: WHEN RECURSE WE USE NEXT STATE
// out || recurse for up right
// out || recurse for up middle
// out || recurse for up left
// out || recurse for left
// out || recurse for right
// out || recurse for down right
// out || recurse for down middle
// out || recurse for down left
pub fn readText() void {}

pub fn readTextHelper(readState: ReadEnum, ptr: usize, rowLength: usize, text: []u8) bool {
    if (readState.validForNextEnum(text[ptr]) == 0) return false;

    var out: bool = false;

    out = true;

    // Up Left
    out = out or readTextHelper(readState.getNext(), ((ptr - rowLength) % rowLength) - 1, rowLength, text);
    // Up Middle
    out = out or readTextHelper(readState.getNext(), (ptr - rowLength) % rowLength, rowLength, text);
    // Up Right
    out = out or readTextHelper(readState.getNext(), ((ptr - rowLength) % rowLength) + 1, rowLength, text);

    // Left
    out = out or readTextHelper(readState.getNext(), ptr - 1, rowLength, text);
    // Right
    out = out or readTextHelper(readState.getNext(), ptr + 1, rowLength, text);

    // Down Left
    out = out or readTextHelper(readState.getNext(), ((ptr + rowLength) % rowLength) - 1, rowLength, text);
    // Down Middle
    out = out or readTextHelper(readState.getNext(), (ptr + rowLength) % rowLength, rowLength, text);
    // Down Right
    out = out or readTextHelper(readState.getNext(), ((ptr + rowLength) % rowLength) + 1, rowLength, text);

    return out or readState.validForNextEnum(text[ptr]) == 7;
}

// pub fn tryReadWord(readState: *StateRead) bool {
//     if (readState.tries == 3) return false;
//
//     // _ = tryReadWord(level + 1);
//     // std.debug.print("{d}\n", .{level});
//     // Up Left
//     // Up Middle
//     // Up Right
//     // Right
//     // Left
//     // Bottom Left
//     // Bottom Middle
//     // Bottom Right
//
//     return false;
// }
//
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
