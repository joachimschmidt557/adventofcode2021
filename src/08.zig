const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/08.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try deduceNumbers(buffered_reader.reader());
    std.debug.print("appearances of 1, 4, 7 and 8: {}\n", .{count});
}

const Pattern = u7;

fn deduceNumbers(reader: anytype) !u64 {
    var buf: [1024]u8 = undefined;

    var sum: u64 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, " ");
        var patterns = [_]Pattern{0} ** 10;
        for (patterns) |*pattern| {
            const raw_pattern = iter.next() orelse return error.MissingData;
            for (raw_pattern) |c| {
                pattern.* |= @as(Pattern, 1) << @intCast(u3, c - 'a');
            }
        }

        const delimiter = iter.next() orelse return error.WrongFormat;
        if (!std.mem.eql(u8, "|", delimiter)) return error.WrongFormat;

        while (iter.next()) |raw_pattern| {
            var pattern: Pattern = 0;
            for (raw_pattern) |c| {
                pattern |= @as(Pattern, 1) << @intCast(u3, c - 'a');
            }

            switch (raw_pattern.len) {
                2, 3, 4, 7 => sum += 1,
                else => {},
            }
        }
    }

    return sum;
}

test "example 1" {
    const text =
        \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
        \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
        \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
        \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
        \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
        \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
        \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
        \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
        \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
        \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try deduceNumbers(fbs.reader());
    try std.testing.expectEqual(@as(u64, 26), count);
}
