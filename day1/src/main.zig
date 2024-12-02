const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

const TrackedList = struct {
    values: []u32,
    ptr: usize,

    pub fn append(self: *TrackedList, value: u32) void {
        self.values[self.ptr] = value;
        self.ptr += 1;
    }
};

const Node = struct {
    value: u32,
    left: ?*Node,
    right: ?*Node,

    // May not need an error union
    pub fn insert(self: *Node, newNode: *Node) void {
        // Right
        if (self.value < newNode.value) {
            if (self.right) |right| {
                right.insert(newNode);
            } else {
                self.right = newNode;
            }

            return;
        }

        if (self.left) |left| {
            left.insert(newNode);
        } else {
            self.left = newNode;
        }
    }

    pub fn init(value: u32, allocator: std.mem.Allocator) !*Node {
        const node = try allocator.create(Node);
        node.* = Node{ .value = value, .left = null, .right = null };

        return node;
    }

    pub fn generateList(self: ?*Node, list: *TrackedList, allocator: std.mem.Allocator) void {
        if (self == null) return;

        // Add lower numbers to list
        if (self.?.left) |left| {
            generateList(left, list, allocator);
        }

        // Add current node value before higher values
        list.append(self.?.value);
        // std.debug.print("{d}; PTR: {d}\n", .{ self.?.value, ptr.* });

        // Add higher values to list
        if (self.?.right) |right| {
            generateList(right, list, allocator);
        }

        allocator.destroy(self.?);
    }

    // Not used anymore
    pub fn utilFree(self: *Node, allocator: std.mem.Allocator) !void {
        if (self.left) |left| {
            try left.utilFree(allocator);
        }

        if (self.right) |right| {
            try right.utilFree(allocator);
        }

        allocator.destroy(self);
    }

    pub fn countInstances(self: ?*Node, value: u32) u16 {
        if (self == null) return 0;
        var count: u16 = 0;

        // std.debug.print("Value: {d}, Node Value: {d}\n", .{ value, self.?.value });
        if (self.?.value < value) {
            if (self.?.right) |right| {
                count = right.countInstances(value);
            }

            return count;
        }

        if (self.?.left) |left| {
            count = left.countInstances(value);
        }

        if (self.?.value == value) {
            count += 1;
        }

        return count;
    }
};

pub fn main() !void {
    try stdout.print("Reading File\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var bufReader = std.io.bufferedReader(file.reader());
    var readerStream = bufReader.reader();

    var firstBTree: *Node = undefined;
    var secondBTree: *Node = undefined;
    var initiated: bool = false;
    var count: usize = 0;

    var buf: [1024]u8 = undefined;
    while (try readerStream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (count += 1) {
        const first = try std.fmt.parseInt(u32, line[0..5], 10);
        const second = try std.fmt.parseInt(u32, line[8..], 10);

        if (!initiated) {
            firstBTree = try Node.init(first, allocator);
            secondBTree = try Node.init(second, allocator);
            initiated = true;
            continue;
        }

        const firstNode = try Node.init(first, allocator);
        const secondNode = try Node.init(second, allocator);

        firstBTree.insert(firstNode);
        secondBTree.insert(secondNode);
    }

    var firstArr = try allocator.alloc(u32, count);
    defer allocator.free(firstArr);
    var firstList = TrackedList{ .values = firstArr[0..], .ptr = 0 };

    // var secondArr = try allocator.alloc(u32, count);
    // defer allocator.free(secondArr);
    // var secondList = TrackedList{ .values = secondArr[0..], .ptr = 0 };

    var rawSimilarity: u64 = 0;
    firstBTree.generateList(&firstList, allocator);
    for (firstList.values) |value| {
        const instances: u16 = secondBTree.countInstances(value);
        rawSimilarity += value * instances;
    }

    try stdout.print("Total Similarity: {d}\n", .{rawSimilarity});

    // secondBTree.generateList(&secondList, allocator);
    //
    // var total: u64 = 0;
    // for (firstList.values, secondList.values) |first, second| {
    //     // try stdout.print("Testing {d}\n", .{@as(i64, first) - @as(i64, second)});
    //     total += @abs(@as(i64, first) - @as(i64, second));
    // }
    //
    // try stdout.print("Total Difference: {d}\n", .{total});

    try secondBTree.utilFree(allocator);
    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
