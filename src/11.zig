const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/11.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try simulate(buffered_reader.reader(), 100);
    std.debug.print("number of flashes: {}\n", .{count});
}

fn simulate(reader: anytype, steps: u64) !u64 {
    var buf: [1024]u8 = undefined;

    var grid_buf = try std.BoundedArray(u8, 100).init(0);
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |c| try grid_buf.append(c - '0');
    }

    const grid = grid_buf.slice();
    const width = 10;
    var flashes: u64 = 0;
    var step: u64 = 0;
    while (step < steps) : (step += 1) {
        for (grid) |*x| x.* += 1;

        while (std.mem.max(u8, grid) > 9) {
            for (grid) |*x, i| {
                if (x.* > 9) {
                    x.* = 0;
                    flashes += 1;

                    const has_north = i >= width;
                    const has_south = i < grid.len - width;
                    const has_west = i % width >= 1;
                    const has_east = i % width < width - 1;

                    // North
                    if (has_north and grid[i - width] != 0) grid[i - width] += 1;

                    // North west
                    if (has_north and has_west and grid[i - width - 1] != 0) grid[i - width - 1] += 1;

                    // North east
                    if (has_north and has_east and grid[i - width + 1] != 0) grid[i - width + 1] += 1;

                    // South
                    if (has_south and grid[i + width] != 0) grid[i + width] += 1;

                    // South west
                    if (has_south and has_west and grid[i + width - 1] != 0) grid[i + width - 1] += 1;

                    // South east
                    if (has_south and has_east and grid[i + width + 1] != 0) grid[i + width + 1] += 1;

                    // West
                    if (has_west and grid[i - 1] != 0) grid[i - 1] += 1;

                    // East
                    if (has_east and grid[i + 1] != 0) grid[i + 1] += 1;
                }
            }
        }
    }

    return flashes;
}

test "example 1" {
    const text =
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try simulate(fbs.reader(), 100);
    try std.testing.expectEqual(@as(u64, 1656), count);
}
