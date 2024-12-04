const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const ReadState = enum {
    NotReading,
    M,
    U,
    L,
    Paren,
    Number1,
    Comma,
    Number2,

    pub fn isValidForState(self: ReadState, char: u8) bool {
        switch (self) {
            ReadState.NotReading => return char == 109,
            ReadState.M => return char == 117,
            ReadState.U => return char == 108,
            ReadState.L => return char == 40,
            ReadState.Paren => return char >= 48 and char <= 57,
            ReadState.Number1 => return (char >= 48 and char <= 57) or (char == 44),
            ReadState.Comma => return char >= 48 and char <= 57,
            ReadState.Number2 => return (char >= 48 and char <= 57) or (char == 41),
        }
    }
};
const ReadStateMachine = struct {
    state: ReadState,

    // Parse char, returns true if done
    pub fn parseChar(self: *ReadStateMachine, char: u8) bool {
        if (!self.state.isValidForState(char)) return;

        switch (self.state) {
            ReadState.NotReading => self.state = ReadState.M,
            ReadState.M => self.state = ReadState.U,
            ReadState.U => self.state = ReadState.L,
            ReadState.L => self.state = ReadState.Paren,
            ReadState.Paren => self.state = ReadState.Number1,
            ReadState.Number1 => if (char == 44) {
                self.state = ReadState.Comma;
            },
            ReadState.Comma => self.state = ReadState.Number2,
            ReadState.Number2 => if (char == 41) {
                self.state = ReadState.NotReading;
                return true;
            },
        }

        return false;
    }
};

pub fn parseFile(allocator: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
}

pub fn parseValidEntry(entry: []u8) !u32 {
    return 1;
}

pub fn main() !void {
    try bw.flush();
}
