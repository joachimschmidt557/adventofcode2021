const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/09.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const risk_level = try calculateRiskLevel(allocator, buffered_reader.reader());
    std.debug.print("product of three largest basins: {}\n", .{risk_level});
}

fn calculateRiskLevel(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var height_map_array_list = std.ArrayList(u8).init(allocator);
    var width: u64 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        assert(line.len > 0); // empty line
        if (width > 0) assert(width == line.len); // different line lengths
        width = line.len;

        try height_map_array_list.appendSlice(line);
    }

    const height_map = height_map_array_list.items;

    // Find all low points
    var low_point_basins = std.AutoHashMap(usize, std.ArrayList(usize)).init(allocator);
    for (height_map) |x, i| {
        const lower_than_north = i < width or x < height_map[i - width];
        const lower_than_south = i >= height_map.len - width or x < height_map[i + width];
        const lower_than_west = i % width < 1 or x < height_map[i - 1];
        const lower_than_east = i % width >= width - 1 or x < height_map[i + 1];

        if (lower_than_north and lower_than_south and lower_than_west and lower_than_east) {
            try low_point_basins.put(i, std.ArrayList(usize).init(allocator));
            try low_point_basins.getPtr(i).?.append(i);
        }
    }

    // Find all basin mappings
    for (height_map) |x, i| {
        if (x == '9') continue;
        if (low_point_basins.contains(i)) continue;

        var pos = i;
        while (!low_point_basins.contains(pos)) {
            const pos_north: ?usize = if (pos < width) null else pos - width;
            const pos_south: ?usize = if (pos >= height_map.len - width) null else pos + width;
            const pos_west: ?usize = if (pos % width < 1) null else pos - 1;
            const pos_east: ?usize = if (pos % width >= width - 1) null else pos + 1;
            const possible_positions = [_]?usize{ pos_north, pos_south, pos_west, pos_east };

            var min: ?usize = null;
            for (possible_positions) |maybe_possible_pos| {
                if (maybe_possible_pos) |possible_pos| {
                    if (min) |current_min| {
                        if (height_map[possible_pos] < height_map[current_min]) {
                            min = possible_pos;
                        }
                    } else {
                        min = possible_pos;
                    }
                }
            }

            pos = min.?; // no minimum found?
        }

        try low_point_basins.getPtr(pos).?.append(i);
    }

    var basin_sizes = try allocator.alloc(usize, low_point_basins.count());
    var iter = low_point_basins.iterator();
    var i: usize = 0;
    while (iter.next()) |entry| {
        basin_sizes[i] = entry.value_ptr.items.len;
        i += 1;
    }

    std.sort.sort(usize, basin_sizes, {}, comptime std.sort.desc(usize));
    return basin_sizes[0] * basin_sizes[1] * basin_sizes[2];
}

test "example 1" {
    const text =
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
    ;

    var fbs = std.io.fixedBufferStream(text);
    const risk_level = try calculateRiskLevel(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 1134), risk_level);
}
