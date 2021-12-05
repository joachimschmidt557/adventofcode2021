const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/05.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try countOverlappingPoints(allocator, buffered_reader.reader());
    std.debug.print("points where at least two lines overlap: {}\n", .{count});
}

const Point = struct {
    x: i64,
    y: i64,
};

const Direction = enum {
    horizontal,
    vertical,
};

const Line = struct {
    p1: Point,
    p2: Point,

    pub fn direction(self: Line) Direction {
        if (self.p1.x == self.p2.x) {
            return .vertical;
        } else if (self.p1.y == self.p2.y) {
            return .horizontal;
        } else {
            unreachable;
        }
    }

    pub fn swapped(self: Line) Line {
        return .{ .p1 = self.p2, .p2 = self.p1 };
    }

    pub fn sorted(self: Line) Line {
        switch (self.direction()) {
            .horizontal => {
                if (self.p1.x > self.p2.x) {
                    return self.swapped();
                } else {
                    return self;
                }
            },
            .vertical => {
                if (self.p1.y > self.p2.y) {
                    return self.swapped();
                } else {
                    return self;
                }
            },
        }
    }
};

fn countOverlappingPoints(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [1024]u8 = undefined;
    var lines = std.ArrayList(Line).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, " ");
        const p1_raw = iter.next() orelse return error.WrongFormat;
        if (!std.mem.eql(u8, "->", iter.next() orelse return error.WrongFormat)) return error.WrongFormat;
        const p2_raw = iter.next() orelse return error.WrongFormat;
        if (iter.next() != null) return error.WrongFormat;

        var p1_raw_iter = std.mem.split(u8, p1_raw, ",");
        const x1 = try std.fmt.parseInt(i64, p1_raw_iter.next() orelse return error.WrongFormat, 10);
        const y1 = try std.fmt.parseInt(i64, p1_raw_iter.next() orelse return error.WrongFormat, 10);
        if (p1_raw_iter.next() != null) return error.WrongFormat;

        var p2_raw_iter = std.mem.split(u8, p2_raw, ",");
        const x2 = try std.fmt.parseInt(i64, p2_raw_iter.next() orelse return error.WrongFormat, 10);
        const y2 = try std.fmt.parseInt(i64, p2_raw_iter.next() orelse return error.WrongFormat, 10);
        if (p2_raw_iter.next() != null) return error.WrongFormat;

        // Only consider horizontal and vertical lines
        if (!(x1 == x2 or y1 == y2)) continue;

        try lines.append(Line{
            .p1 = .{ .x = x1, .y = y1 },
            .p2 = .{ .x = x2, .y = y2 },
        });
    }

    var overlapping_points = std.AutoHashMap(Point, void).init(allocator);
    for (lines.items) |line_1, i| {
        if (i == lines.items.len - 1) continue;
        for (lines.items[i + 1 ..]) |line_2| {
            const sorted_line_1 = line_1.sorted();
            const sorted_line_2 = line_2.sorted();

            if (line_1.direction() == line_2.direction()) {
                switch (line_1.direction()) {
                    .horizontal => {
                        if (line_1.p1.y != line_2.p1.y) continue;

                        const first_line = if (sorted_line_1.p1.x < sorted_line_2.p1.x) sorted_line_1 else sorted_line_2;
                        const second_line = if (sorted_line_1.p1.x < sorted_line_2.p1.x) sorted_line_2 else sorted_line_1;

                        var x: i64 = second_line.p1.x;
                        while (x <= first_line.p2.x and x <= second_line.p2.x) : (x += 1) {
                            // std.debug.print("- adding {} {} for lines {} and {}\n", .{ x, first_line.p1.y, line_1, line_2 });
                            try overlapping_points.put(.{
                                .x = x,
                                .y = first_line.p1.y,
                            }, {});
                        }
                    },
                    .vertical => {
                        if (line_1.p1.x != line_2.p1.x) continue;

                        const first_line = if (sorted_line_1.p1.y < sorted_line_2.p1.y) sorted_line_1 else sorted_line_2;
                        const second_line = if (sorted_line_1.p1.y < sorted_line_2.p1.y) sorted_line_2 else sorted_line_1;

                        var y: i64 = second_line.p1.y;
                        while (y <= first_line.p2.y and y <= second_line.p2.y) : (y += 1) {
                            // std.debug.print("| adding {} {} for lines {} and {}\n", .{ first_line.p1.x, y, line_1, line_2 });
                            try overlapping_points.put(.{
                                .x = first_line.p1.x,
                                .y = y,
                            }, {});
                        }
                    },
                }
            } else {
                const horizontal_line = if (sorted_line_1.direction() == .horizontal) sorted_line_1 else sorted_line_2;
                const vertical_line = if (sorted_line_1.direction() == .horizontal) sorted_line_2 else sorted_line_1;

                if (horizontal_line.p1.x <= vertical_line.p1.x and vertical_line.p1.x <= horizontal_line.p2.x and
                    vertical_line.p1.y <= horizontal_line.p1.y and horizontal_line.p1.y <= vertical_line.p2.y)
                {
                    // std.debug.print("x adding {} {} for lines {} and {}\n", .{ vertical_line.p1.x, horizontal_line.p1.y, line_1, line_2 });
                    try overlapping_points.put(.{
                        .x = vertical_line.p1.x,
                        .y = horizontal_line.p1.y,
                    }, {});
                }
            }
        }
    }

    // {
    //     var iter = overlapping_points.iterator();
    //     while (iter.next()) |entry| {
    //         std.debug.print("{}\n", .{entry.key_ptr.*});
    //     }
    // }

    return overlapping_points.count();
}

test "example 1" {
    const text =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try countOverlappingPoints(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 5), count);
}
