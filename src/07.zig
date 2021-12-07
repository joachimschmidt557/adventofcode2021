const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/07.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try calculateFuelConsumption(allocator, buffered_reader.reader());
    std.debug.print("fuel consumption: {}\n", .{count});
}

fn calculateFuelConsumption(gpa: std.mem.Allocator, reader: anytype) !i64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var crabs = std.ArrayList(i64).init(allocator);

    const line = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.MissingData;
    if ((try reader.readUntilDelimiterOrEof(&buf, '\n')) != null) return error.UnexpectedData;
    var iter = std.mem.split(u8, line, ",");
    while (iter.next()) |item| {
        const crab_pos = try std.fmt.parseInt(i64, item, 10);
        try crabs.append(crab_pos);
    }

    std.sort.sort(i64, crabs.items, {}, comptime std.sort.asc(i64));
    const median = crabs.items[crabs.items.len / 2];

    var fuel_consumption: i64 = 0;
    for (crabs.items) |x| {
        fuel_consumption += try std.math.absInt(x - median);
    }

    return fuel_consumption;
}

test "example 1" {
    const text =
        \\16,1,2,0,4,2,7,1,2,14
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try calculateFuelConsumption(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(i64, 37), count);
}
