const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/13.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try fold(allocator, buffered_reader.reader());
    std.debug.print("number of dots after one fold: {}\n", .{count});
}

const Point = packed struct { x: u32, y: u32 };

fn fold(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var parse_mode: enum { dots, fold_instructions } = .dots;
    var dots = std.ArrayList(u64).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        switch (parse_mode) {
            .dots => {
                if (line.len == 0) {
                    parse_mode = .fold_instructions;
                } else {
                    var iter = std.mem.split(u8, line, ",");
                    const x = try std.fmt.parseInt(u32, iter.next() orelse return error.WrongFormat, 10);
                    const y = try std.fmt.parseInt(u32, iter.next() orelse return error.WrongFormat, 10);
                    if (iter.next() != null) return error.WrongFormat;

                    try dots.append(@bitCast(u64, Point{ .x = x, .y = y }));
                }
            },
            .fold_instructions => {
                var iter = std.mem.split(u8, line, "=");
                const axis_x_y = iter.next() orelse return error.WrongFormat;
                const axis_pos = try std.fmt.parseInt(u32, iter.next() orelse return error.WrongFormat, 10);
                if (iter.next() != null) return error.WrongFormat;

                if (std.mem.eql(u8, "fold along x", axis_x_y)) {
                    var i: usize = 0;
                    while (i < dots.items.len) : (i += 1) {
                        const p = @bitCast(Point, dots.items[i]);
                        if (p.x > axis_pos) {
                            const new_x = p.x - (2 * (p.x - axis_pos));
                            const new_p = Point{ .x = new_x, .y = p.y };
                            const already_exists_before = i > 0 and std.mem.indexOfScalar(u64, dots.items[0 .. i - 1], @bitCast(u64, new_p)) != null;
                            const already_exists_after = std.mem.indexOfScalarPos(u64, dots.items, i + 1, @bitCast(u64, new_p)) != null;
                            const already_exists = already_exists_before or already_exists_after;
                            if (already_exists) {
                                _ = dots.swapRemove(i);
                                i -= 1;
                            } else {
                                dots.items[i] = @bitCast(u64, new_p);
                            }
                        }
                    }
                } else if (std.mem.eql(u8, "fold along y", axis_x_y)) {
                    var i: usize = 0;
                    while (i < dots.items.len) : (i += 1) {
                        const p = @bitCast(Point, dots.items[i]);
                        if (p.y > axis_pos) {
                            const new_y = p.y - (2 * (p.y - axis_pos));
                            const new_p = Point{ .x = p.x, .y = new_y };
                            const already_exists_before = i > 0 and std.mem.indexOfScalar(u64, dots.items[0 .. i - 1], @bitCast(u64, new_p)) != null;
                            const already_exists_after = std.mem.indexOfScalarPos(u64, dots.items, i + 1, @bitCast(u64, new_p)) != null;
                            const already_exists = already_exists_before or already_exists_after;
                            if (already_exists) {
                                _ = dots.swapRemove(i);
                                i -= 1;
                            } else {
                                dots.items[i] = @bitCast(u64, new_p);
                            }
                        }
                    }
                } else unreachable;

                return dots.items.len;
            },
        }
    }

    return error.NoFoldInstruction;
}

test "example 1" {
    const text =
        \\6,10
        \\0,14
        \\9,10
        \\0,3
        \\10,4
        \\4,11
        \\6,0
        \\6,12
        \\4,1
        \\0,13
        \\10,12
        \\3,4
        \\3,0
        \\8,4
        \\1,10
        \\2,14
        \\8,10
        \\9,0
        \\
        \\fold along y=7
        \\fold along x=5
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try fold(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 17), count);
}
