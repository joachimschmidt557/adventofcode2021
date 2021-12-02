const std = @import("std");

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/02.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const pos = try navigate(buffered_reader.reader());
    std.debug.print("horizontal * depth: {}\n", .{pos.horizontal * pos.depth});
}

const Position = struct {
    horizontal: i64 = 0,
    depth: i64 = 0,
};

fn navigate(reader: anytype) !Position {
    var pos: Position = .{};
    var aim: i64 = 0;
    var buf: [128]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, " ");
        const direction = iter.next() orelse return error.WrongFormat;
        const amout_raw = iter.next() orelse return error.WrongFormat;
        if (iter.next() != null) return error.WrongFormat;

        const amount = try std.fmt.parseInt(i64, amout_raw, 10);

        if (std.mem.eql(u8, "forward", direction)) {
            pos.horizontal += amount;
            pos.depth += amount * aim;
        } else if (std.mem.eql(u8, "down", direction)) {
            aim += amount;
        } else if (std.mem.eql(u8, "up", direction)) {
            aim -= amount;
        } else return error.WrongFormat;
    }

    return pos;
}

test "example 1" {
    const text =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
    ;

    var fbs = std.io.fixedBufferStream(text);
    const pos = try navigate(fbs.reader());
    try std.testing.expectEqual(@as(i64, 900), pos.horizontal * pos.depth);
}
