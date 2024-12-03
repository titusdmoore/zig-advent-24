const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const EntryType = enum {
    unknown,
    increasing,
    decreasing,
};

pub fn attemptResolution(inputList: std.ArrayList(u32)) bool {
    for (0..inputList.items.len) |i| {
        std.debug.print("{d}\n", .{inputList.items[i]});
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
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

        if (!attemptResolution(entryList)) continue;

        if (valid) {
            validCount += 1;
            try stdout.print("Valid Entry: {s}\n", .{line});
            continue;
        }
    }

    try stdout.print("Total Safe Entries: {d}\n", .{validCount});

    try bw.flush();
}
