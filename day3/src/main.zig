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
    D,
    O,
    N,
    APOS,
    T,
    PENDING_TOGGLE,

    pub fn isValidForState(self: ReadState, char: u8, charCount: u8) bool {
        switch (self) {
            ReadState.NotReading => return char == 109 or char == 100,
            ReadState.M => return char == 117,
            ReadState.U => return char == 108,
            ReadState.L => return char == 40,
            ReadState.Paren => return char >= 48 and char <= 57,
            ReadState.Number1 => return ((char >= 48 and char <= 57) and charCount < 4) or (char == 44),
            ReadState.Comma => return char >= 48 and char <= 57,
            ReadState.Number2 => return ((char >= 48 and char <= 57) and charCount < 4) or (char == 41),
            ReadState.D => return char == 111,
            ReadState.O => return char == 40 or char == 110,
            ReadState.N => return char == '\'',
            ReadState.APOS => return char == 116,
            ReadState.T => return char == 40,
            ReadState.PENDING_TOGGLE => return char == 41,
        }
    }
};

const MultEnabled = enum { Enabled, Disabled, PendingEnabled, PendingDisabled };

const ReadStateMachine = struct {
    state: ReadState,
    charCount: u8,
    multEnabled: MultEnabled,

    // Parse char, returns true if done
    pub fn parseChar(self: *ReadStateMachine, char: u8) bool {
        if (!self.state.isValidForState(char, self.charCount)) {
            self.state = ReadState.NotReading;
            self.multEnabled = @enumFromInt(@mod(@intFromEnum(self.multEnabled), 2));
            return false;
        }

        switch (self.state) {
            ReadState.NotReading => {
                switch (char) {
                    'm' => self.state = ReadState.M,
                    'd' => self.state = ReadState.D,
                    else => unreachable,
                }
            },
            ReadState.M => self.state = ReadState.U,
            ReadState.U => self.state = ReadState.L,
            ReadState.L => self.state = ReadState.Paren,
            ReadState.Paren => self.state = ReadState.Number1,
            ReadState.Number1 => {
                if (char == 44) {
                    self.state = ReadState.Comma;
                    return false;
                }

                self.charCount += 1;
            },
            ReadState.Comma => self.state = ReadState.Number2,
            ReadState.Number2 => {
                if (char == 41) {
                    self.state = ReadState.NotReading;
                    self.charCount = 0;
                    return true;
                }

                self.charCount += 1;
            },
            ReadState.D => self.state = ReadState.O,
            ReadState.O => {
                switch (char) {
                    'n' => {
                        self.state = ReadState.N;
                        self.multEnabled = MultEnabled.PendingDisabled;
                    },
                    '(' => {
                        self.state = ReadState.PENDING_TOGGLE;
                        self.multEnabled = MultEnabled.PendingEnabled;
                    },
                    else => unreachable,
                }
            },
            ReadState.N => self.state = ReadState.APOS,
            ReadState.APOS => self.state = ReadState.T,
            ReadState.T => self.state = ReadState.PENDING_TOGGLE,
            ReadState.PENDING_TOGGLE => {
                self.multEnabled = @enumFromInt(@mod(@intFromEnum(self.multEnabled), 2));
                self.state = ReadState.NotReading;
            },
        }

        self.charCount = 0;
        return false;
    }
};

pub fn parseFile(readState: *ReadStateMachine, allocator: std.mem.Allocator) !u64 {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();

    const data = try file.reader().readAllAlloc(allocator, stat.size);
    defer allocator.free(data);

    var totalValue: u64 = 0;
    var slowPtr: usize = 0;

    for (0..data.len) |ptr| {
        if (readState.parseChar(data[ptr])) {
            if (readState.multEnabled == MultEnabled.Enabled) {
                totalValue += try parseValidEntry(data[slowPtr + 4 .. ptr]);
            }
        }

        if (readState.state == ReadState.NotReading or readState.state == ReadState.M) {
            slowPtr = ptr;
        }
    }

    return totalValue;
}

pub fn parseValidEntry(entry: []u8) !u32 {
    const commaIdx = for (0..entry.len) |idx| {
        if (entry[idx] == ',') break idx;
    } else 999;

    if (commaIdx == 999) {
        return 0;
    }

    return try std.fmt.parseInt(u32, entry[0..commaIdx], 10) * try std.fmt.parseInt(u32, entry[commaIdx + 1 ..], 10);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var readState = ReadStateMachine{ .state = ReadState.NotReading, .charCount = 0, .multEnabled = MultEnabled.Enabled };

    const out = try parseFile(&readState, allocator);

    try stdout.print("{d}\n", .{out});

    try bw.flush();
}
