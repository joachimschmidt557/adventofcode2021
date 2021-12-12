const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/12.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try countPaths(allocator, buffered_reader.reader());
    std.debug.print("number of paths: {}\n", .{count});
}

fn countPaths(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var nodes = std.StringHashMap(u32).init(allocator);
    try nodes.put("start", 0);
    try nodes.put("end", 1);
    var edges = std.ArrayList(std.ArrayList(u32)).init(allocator);
    try edges.appendNTimes(std.ArrayList(u32).init(allocator), 2);
    var big_caves = std.ArrayList(u32).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, "-");
        const origin = iter.next() orelse return error.WrongFormat;
        const dest = iter.next() orelse return error.WrongFormat;
        if (iter.next() != null) return error.WrongFormat;

        if (!nodes.contains(origin)) {
            const id = nodes.count();
            try nodes.put(try allocator.dupe(u8, origin), id);
            try edges.append(std.ArrayList(u32).init(allocator));
            if ('A' <= origin[0] and origin[0] <= 'Z') try big_caves.append(id);
        }
        if (!nodes.contains(dest)) {
            const id = nodes.count();
            try nodes.put(try allocator.dupe(u8, dest), id);
            try edges.append(std.ArrayList(u32).init(allocator));
            if ('A' <= dest[0] and dest[0] <= 'Z') try big_caves.append(id);
        }

        const origin_id = nodes.get(origin).?;
        const dest_id = nodes.get(dest).?;
        try edges.items[origin_id].append(dest_id);
        try edges.items[dest_id].append(origin_id);
    }

    // {
    //     std.debug.print("--- Nodes ---\n", .{});
    //     var iter = nodes.iterator();
    //     while (iter.next()) |entry| {
    //         std.debug.print("{s}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    //     }
    // }

    // {
    //     std.debug.print("--- Edges ---\n", .{});
    //     for (edges.items) |x, i| {
    //         std.debug.print("{}: {any}\n", .{ i, x.items });
    //     }
    // }

    // {
    //     std.debug.print("--- Big caves ---\n", .{});
    //     for (big_caves.items) |x| {
    //         std.debug.print("{}\n", .{x});
    //     }
    // }

    return countFurtherPaths(
        allocator,
        edges.items,
        big_caves.items,
        &[_]u32{0},
    );
}

fn countFurtherPaths(
    allocator: std.mem.Allocator,
    edges: []const std.ArrayList(u32),
    big_caves: []const u32,
    current_path: []const u32,
) std.mem.Allocator.Error!u64 {
    const current_node = current_path[current_path.len - 1];
    if (current_node == 1) return 1;

    const neighbors = edges[current_node].items;
    var path_array_list = std.ArrayList(u32).fromOwnedSlice(allocator, try allocator.dupe(u32, current_path));
    defer path_array_list.deinit();
    var sum: u64 = 0;

    for (neighbors) |neighbor| {
        // check if we visited this node before and this node is not a
        // big cave
        const visited_before = std.mem.indexOfScalar(u32, current_path, neighbor) != null;
        const big_cave = std.mem.indexOfScalar(u32, big_caves, neighbor) != null;
        if (visited_before and !big_cave) continue;

        try path_array_list.append(neighbor);
        defer _ = path_array_list.pop();

        sum += try countFurtherPaths(
            allocator,
            edges,
            big_caves,
            path_array_list.items,
        );
    }

    return sum;
}

test "example 1" {
    const text =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try countPaths(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 10), count);
}

test "example 2" {
    const text =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try countPaths(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 19), count);
}

test "example 1" {
    const text =
        \\fs-end
        \\he-DX
        \\fs-he
        \\start-DX
        \\pj-DX
        \\end-zg
        \\zg-sl
        \\zg-pj
        \\pj-he
        \\RW-he
        \\fs-DX
        \\pj-RW
        \\zg-RW
        \\start-pj
        \\he-WI
        \\zg-he
        \\pj-fs
        \\start-RW
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try countPaths(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 226), count);
}
