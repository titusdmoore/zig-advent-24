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
pub fn readText(text: std.ArrayList([]u8)) u32 {
    var count: u32 = 0;

    for (0..text.items.len) |line| {
        for (0..text.items[line].len) |char| {
            count += readTextHelper(ReadEnum.None, char, line, text);
        }
    }

    return count;
}

pub fn readTextHelper(readState: ReadEnum, ptr: usize, rowNum: usize, text: std.ArrayList([]u8)) u32 {
    if (readState.validForNextEnum(text.items[rowNum][ptr]) == 0 or (ptr == 0 or rowNum == 0) or (ptr + 1 >= text.items[0].len or rowNum + 1 >= text.items.len)) return 0;

    var out: u32 = 0;

    // Up Left
    out += readTextHelper(readState.getNext(), ptr - 1, rowNum - 1, text);
    // Up Middle
    out += readTextHelper(readState.getNext(), ptr, rowNum - 1, text);
    // Up Right
    out += readTextHelper(readState.getNext(), ptr + 1, rowNum - 1, text);

    // Left
    out += readTextHelper(readState.getNext(), ptr - 1, rowNum, text);
    // Right
    out += readTextHelper(readState.getNext(), ptr + 1, rowNum, text);

    // Down Left
    out += readTextHelper(readState.getNext(), ptr - 1, rowNum + 1, text);
    // Down Middle
    out += readTextHelper(readState.getNext(), ptr, rowNum + 1, text);
    // Down Right
    out += readTextHelper(readState.getNext(), ptr + 1, rowNum + 1, text);

    std.debug.print("Read for: {c}; At: {any}; Value: {d}, At: {d}, {d}\n", .{ text.items[rowNum][ptr], readState, readState.validForNextEnum(text.items[rowNum][ptr]), ptr, rowNum });
    const runTimeValue: u32 = if (readState.validForNextEnum(text.items[rowNum][ptr]) == 3) 1 else 0;
    if (runTimeValue == 1) {
        std.debug.print("Found match\n", .{});
    }
    return out + runTimeValue;
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

    var list = std.ArrayList([]u8).init(allocator);
    defer list.deinit();

    var buf: [1024]u8 = undefined;
    while (try readerStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try list.append(line);
    }

    std.debug.print("{d}\n", .{list.items.len});
    std.debug.print("{d}\n", .{readText(list)});

    try bw.flush();
}
