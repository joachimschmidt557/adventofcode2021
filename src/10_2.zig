const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/10.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const total_score = try calculateMiddleScore(allocator, buffered_reader.reader());
    std.debug.print("middle score: {}\n", .{total_score});
}

fn calculateMiddleScore(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var scores = std.ArrayList(u64).init(allocator);

    lines: while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parenthesis_stack = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try parenthesis_stack.append(c),
                ')' => {
                    if (parenthesis_stack.pop() != '(') continue :lines;
                },
                ']' => {
                    if (parenthesis_stack.pop() != '[') continue :lines;
                },
                '}' => {
                    if (parenthesis_stack.pop() != '{') continue :lines;
                },
                '>' => {
                    if (parenthesis_stack.pop() != '<') continue :lines;
                },
                else => return error.InvalidSymbol,
            }
        }

        var score: u64 = 0;
        var i: usize = parenthesis_stack.items.len;
        while (i > 0) : (i -= 1) {
            const points: u64 = switch (parenthesis_stack.items[i - 1]) {
                '(' => 1,
                '[' => 2,
                '{' => 3,
                '<' => 4,
                else => unreachable,
            };
            score = score * 5 + points;
        }
        try scores.append(score);
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));

    return scores.items[scores.items.len / 2];
}

test "example 1" {
    const text =
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    ;

    var fbs = std.io.fixedBufferStream(text);
    const total_score = try calculateMiddleScore(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 288957), total_score);
}
