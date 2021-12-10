const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/10.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const total_score = try calculateTotalScore(allocator, buffered_reader.reader());
    std.debug.print("total score: {}\n", .{total_score});
}

fn calculateTotalScore(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var sum: u64 = 0;

    lines: while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parenthesis_stack = std.ArrayList(u8).init(allocator);

        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try parenthesis_stack.append(c),
                ')' => {
                    if (parenthesis_stack.pop() != '(') {
                        sum += 3;
                        continue :lines;
                    }
                },
                ']' => {
                    if (parenthesis_stack.pop() != '[') {
                        sum += 57;
                        continue :lines;
                    }
                },
                '}' => {
                    if (parenthesis_stack.pop() != '{') {
                        sum += 1197;
                        continue :lines;
                    }
                },
                '>' => {
                    if (parenthesis_stack.pop() != '<') {
                        sum += 25137;
                        continue :lines;
                    }
                },
                else => return error.InvalidSymbol,
            }
        }
    }

    return sum;
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
    const total_score = try calculateTotalScore(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 26397), total_score);
}
