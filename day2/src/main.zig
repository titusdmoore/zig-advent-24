const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const EntryType = enum {
    unknown,
    increasing,
    decreasing,
};

pub fn validDelta(prevValue: u32, currentValue: u32, changeType: EntryType) bool {
    const delta: i64 = @as(i64, prevValue) - @as(i64, currentValue);
    switch (changeType) {
        EntryType.increasing => {
            return !(prevValue >= currentValue or @abs(delta) > 3);
        },
        EntryType.decreasing => {
            return !(prevValue <= currentValue or @abs(delta) > 3);
        },
        EntryType.unknown => {
            return false;
        },
    }
}

pub fn validateList(list: *std.ArrayList(u32), entryType: EntryType) bool {
    var out = true;
    for (1..list.items.len) |ptr| {
        out = out and validDelta(list.items[ptr - 1], list.items[ptr], entryType);
    }

    return out;
}

pub fn validateSlice(list: []u32, entryType: EntryType, len: usize) bool {
    var out = true;
    for (1..len) |ptr| {
        out = out and validDelta(list[ptr - 1], list[ptr], entryType);
    }

    return out;
}

pub fn bruteResolve(inputList: *std.ArrayList(u32), allocator: std.mem.Allocator) !bool {
    var testList: []u32 = try allocator.alloc(u32, inputList.items.len - 1);
    defer allocator.free(testList);

    var determine: i64 = 0;
    for (1..inputList.items.len) |i| {
        determine += if (inputList.items[i - 1] < inputList.items[i]) 1 else if (inputList.items[i - 1] == inputList.items[i]) 0 else -1;
    }
    const entryType: EntryType = if (determine > 0) EntryType.increasing else EntryType.decreasing;

    if (entryType == EntryType.unknown) return false;

    for (0..inputList.items.len) |skip| {
        // var out: bool = true;
        var idx: usize = 0;
        for (0..inputList.items.len) |ptr| {
            if (ptr == skip) continue;

            testList[idx] = inputList.items[ptr];
            idx += 1;

            if (entryType == EntryType.unknown) unreachable;
        }

        if (validateSlice(testList, entryType, inputList.items.len - 1)) {
            return true;
        }
    }

    return false;
}

pub fn attemptResolution(inputList: *std.ArrayList(u32)) bool {
    // const entryType: EntryType = for (1..inputList.items.len) |ptr| {
    //     if (inputList.items[ptr - 1] > inputList.items[ptr]) {
    //         break EntryType.decreasing;
    //     } else if (inputList.items[ptr - 1] < inputList.items[ptr]) {
    //         break EntryType.increasing;
    //     }
    // } else EntryType.unknown;

    var determine: i64 = 0;
    for (1..inputList.items.len) |i| {
        determine += if (inputList.items[i - 1] < inputList.items[i]) 1 else if (inputList.items[i - 1] == inputList.items[i]) 0 else -1;
    }
    const entryType: EntryType = if (determine > 0) EntryType.increasing else EntryType.decreasing;

    if (entryType == EntryType.unknown) return false;

    var debugChanged: bool = false;
    std.debug.print("Before: {any}\n", .{inputList.items});
    std.debug.print("Testing Type: {any}\n", .{entryType});

    for (1..inputList.items.len) |ptr| {
        if (!validDelta(inputList.items[ptr - 1], inputList.items[ptr], entryType)) {
            // Can we remove the prev el
            if (ptr - 1 == 0 or validDelta(inputList.items[ptr - 2], inputList.items[ptr], entryType)) {
                _ = inputList.orderedRemove(ptr - 1);
                debugChanged = true;
                break;
            }

            // Can we remove us
            if (ptr == inputList.items.len - 1 or validDelta(inputList.items[ptr - 1], inputList.items[ptr + 1], entryType)) {
                _ = inputList.orderedRemove(ptr);
                debugChanged = true;
                break;
            }
        }
    }

    if (debugChanged and validateList(inputList, entryType)) {
        std.debug.print("Changed and valid\n", .{});
    } else {
        std.debug.print("Test:   {any}\n", .{inputList.items});
    }

    return validateList(inputList, entryType);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    // var file = try std.fs.cwd().openFile("test.txt", .{});
    // var file = try std.fs.cwd().openFile("edgeTest.txt", .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    var readerStream = bufReader.reader();

    var validCount: u16 = 0;

    var buf: [1024]u8 = undefined;
    while (try readerStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var splitItems = std.mem.splitScalar(u8, line, ' ');
        var entryList = std.ArrayList(u32).init(allocator);
        defer entryList.deinit();

        var entryType: EntryType = EntryType.unknown;
        var valid: bool = true;

        while (splitItems.next()) |item| {
            const intItem = try std.fmt.parseInt(u32, item, 10);
            try entryList.append(intItem);

            if (entryList.items.len > 1) {
                switch (entryType) {
                    EntryType.unknown => {
                        const lastItem = entryList.items[entryList.items.len - 2];
                        const thisItem = entryList.items[entryList.items.len - 1];
                        const delta: i64 = @as(i64, lastItem) - @as(i64, thisItem);

                        if (@abs(delta) > 3 or lastItem == thisItem) valid = false;

                        // This should only happen once, when we get to two items, I make that assumption here
                        entryType = if (lastItem > thisItem) EntryType.decreasing else EntryType.increasing;
                    },
                    EntryType.increasing => {
                        const lastItem = entryList.items[entryList.items.len - 2];
                        const thisItem = entryList.items[entryList.items.len - 1];
                        const delta: i64 = @as(i64, lastItem) - @as(i64, thisItem);

                        if (lastItem >= thisItem or @abs(delta) > 3) {
                            valid = false;
                        }
                    },
                    EntryType.decreasing => {
                        const lastItem = entryList.items[entryList.items.len - 2];
                        const thisItem = entryList.items[entryList.items.len - 1];
                        const delta: i64 = @as(i64, lastItem) - @as(i64, thisItem);

                        if (lastItem <= thisItem or @abs(delta) > 3) {
                            valid = false;
                        }
                    },
                }
            }
        }

        // if (valid or attemptResolution(&entryList)) {
        // if (valid or attemptResolution(&entryList)) {
        if (valid or try bruteResolve(&entryList, allocator)) {
            validCount += 1;
            continue;
        }
    }

    try stdout.print("Total Safe Entries: {d}\n", .{validCount});

    try bw.flush();
}
