const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/13.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const dots = try fold(allocator, buffered_reader.reader());
    defer allocator.free(dots);

    try printDots(allocator, dots);
}

const Point = packed struct { x: u32, y: u32 };

fn printDots(gpa: std.mem.Allocator, dots: []const u64) !void {
    var max_x: u32 = 0;
    var max_y: u32 = 0;

    for (dots) |x| {
        const dot = @bitCast(Point, x);
        max_x = std.math.max(max_x, dot.x);
        max_y = std.math.max(max_y, dot.y);
    }

    const width = max_x + 1;
    const height = max_y + 1;
    const dot_screen = try gpa.alloc(bool, width * height);
    defer gpa.free(dot_screen);
    std.mem.set(bool, dot_screen, false);

    for (dots) |x| {
        const dot = @bitCast(Point, x);
        dot_screen[dot.x + width * dot.y] = true;
    }

    const stdout = std.io.getStdOut();
    var buffered_writer = std.io.bufferedWriter(stdout.writer());
    const writer = buffered_writer.writer();

    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            try writer.writeAll(if (dot_screen[x + width * y]) "#" else ".");
        }
        try writer.writeAll("\n");
    }

    try buffered_writer.flush();
}

fn fold(gpa: std.mem.Allocator, reader: anytype) ![]const u64 {
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
                    while (i < dots.items.len) {
                        const p = @bitCast(Point, dots.items[i]);
                        if (p.x > axis_pos) {
                            const new_x = p.x - (2 * (p.x - axis_pos));
                            const new_p = Point{ .x = new_x, .y = p.y };
                            const already_exists_before = i > 0 and std.mem.indexOfScalar(u64, dots.items[0 .. i - 1], @bitCast(u64, new_p)) != null;
                            const already_exists_after = std.mem.indexOfScalarPos(u64, dots.items, i + 1, @bitCast(u64, new_p)) != null;
                            const already_exists = already_exists_before or already_exists_after;
                            if (already_exists) {
                                _ = dots.swapRemove(i);
                                continue;
                            } else {
                                dots.items[i] = @bitCast(u64, new_p);
                            }
                        }
                        i += 1;
                    }
                } else if (std.mem.eql(u8, "fold along y", axis_x_y)) {
                    var i: usize = 0;
                    while (i < dots.items.len) {
                        const p = @bitCast(Point, dots.items[i]);
                        if (p.y > axis_pos) {
                            const new_y = p.y - (2 * (p.y - axis_pos));
                            const new_p = Point{ .x = p.x, .y = new_y };
                            const already_exists_before = i > 0 and std.mem.indexOfScalar(u64, dots.items[0 .. i - 1], @bitCast(u64, new_p)) != null;
                            const already_exists_after = std.mem.indexOfScalarPos(u64, dots.items, i + 1, @bitCast(u64, new_p)) != null;
                            const already_exists = already_exists_before or already_exists_after;
                            if (already_exists) {
                                _ = dots.swapRemove(i);
                                continue;
                            } else {
                                dots.items[i] = @bitCast(u64, new_p);
                            }
                        }
                        i += 1;
                    }
                } else unreachable;
            },
        }
    }

    return try gpa.dupe(u64, dots.items);
}
