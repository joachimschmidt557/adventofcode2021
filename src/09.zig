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
    std.debug.print("sum of risk levels: {}\n", .{risk_level});
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
    var sum: u64 = 0;
    for (height_map) |x, i| {
        const lower_than_north = i < width or x < height_map[i - width];
        const lower_than_south = i >= height_map.len - width or x < height_map[i + width];
        const lower_than_west = i % width < 1 or x < height_map[i - 1];
        const lower_than_east = i % width >= width - 1 or x < height_map[i + 1];

        if (lower_than_north and lower_than_south and lower_than_west and lower_than_east) {
            sum += x - '0' + 1;
        }
    }

    return sum;
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
    try std.testing.expectEqual(@as(u64, 15), risk_level);
}
