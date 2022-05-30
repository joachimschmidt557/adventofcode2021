const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/15.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const risk_level = try findPath(allocator, buffered_reader.reader());
    std.debug.print("lowest total risk: {}\n", .{risk_level});
}

const Node = struct {
    weight: u8,
    pred: ?usize = null,
    dist: u32 = std.math.maxInt(u32),

    fn compare(a: Node, b: Node) std.math.Order {
        return std.math.order(a.dist, b.dist);
    }
};

const PQNode = usize;
const PriorityQueue = std.PriorityQueue(PQNode, void, comparePQNode);

fn comparePQNode(context: void, a: PQNode, b: PQNode) std.math.Order {
    _ = context;
    return map.items[a].compare(map.items[b]);
}

fn relax(queue: *PriorityQueue, origin_i: usize, dest_i: usize) !void {
    const origin = map.items[origin_i];
    const dest = &map.items[dest_i];
    const weight = dest.weight;
    const alternative_dist = origin.dist + weight;

    if (std.math.order(dest.dist, alternative_dist) == .gt) {
        const remove_index = std.mem.indexOfScalar(PQNode, queue.items[0..queue.len], dest_i).?;
        assert(queue.removeIndex(remove_index) == dest_i);

        dest.dist = alternative_dist;
        dest.pred = origin_i;

        try queue.add(dest_i);
    }
}

var map: std.ArrayList(Node) = undefined;

fn findPath(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    map = std.ArrayList(Node).init(allocator);
    var width: usize = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) return error.EmptyLine;
        if (width == 0) {
            width = line.len;
        } else {
            assert(line.len == width);
        }

        for (line) |c| try map.append(.{ .weight = c - '0' });
    }

    var queue = PriorityQueue.init(allocator, {});
    map.items[0].dist = 0;
    for (map.items) |_, i| try queue.add(i);

    while (queue.removeOrNull()) |i| {
        const north: ?usize = if (i >= width) i - width else null;
        const south: ?usize = if (i < map.items.len - width) i + width else null;
        const west: ?usize = if (i % width >= 1) i - 1 else null;
        const east: ?usize = if (i % width < width - 1) i + 1 else null;

        if (north) |j| try relax(&queue, i, j);
        if (south) |j| try relax(&queue, i, j);
        if (west) |j| try relax(&queue, i, j);
        if (east) |j| try relax(&queue, i, j);
    }

    return map.items[map.items.len - 1].dist;
}

test "example 1" {
    const text =
        \\1163751742
        \\1381373672
        \\2136511328
        \\3694931569
        \\7463417111
        \\1319128137
        \\1359912421
        \\3125421639
        \\1293138521
        \\2311944581
    ;

    var fbs = std.io.fixedBufferStream(text);
    const risk_level = try findPath(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 40), risk_level);
}
