const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    var readerStream = bufReader.reader();

    var buf: [1024]u8 = undefined;
    while (try readerStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try stdout.print("{s}\n", .{line});
        var splitItems = std.mem.splitScalar(u8, line, ' ');

        while (splitItems.next()) |item| {}
    }

    try bw.flush();
}
