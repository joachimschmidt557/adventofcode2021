const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/08.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try deduceNumbers(buffered_reader.reader());
    std.debug.print("sum of all output values: {}\n", .{count});
}

const Pattern = u7;

fn deduceNumbers(reader: anytype) !u64 {
    var buf: [1024]u8 = undefined;

    var sum: u64 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.split(u8, line, " ");
        var pattern_map = [_]Pattern{0} ** 10;
        var patterns_with_len_5 = try std.BoundedArray(Pattern, 3).init(0);
        var patterns_with_len_6 = try std.BoundedArray(Pattern, 3).init(0);

        {
            var i: u8 = 0;
            while (i < 10) : (i += 1) {
                var pattern: Pattern = 0;
                const raw_pattern = iter.next() orelse return error.MissingData;
                for (raw_pattern) |c| {
                    pattern |= @as(Pattern, 1) << @intCast(u3, c - 'a');
                }

                assert(raw_pattern.len == @popCount(Pattern, pattern));
                switch (raw_pattern.len) {
                    2 => pattern_map[1] = pattern,
                    4 => pattern_map[4] = pattern,
                    3 => pattern_map[7] = pattern,
                    7 => pattern_map[8] = pattern,
                    5 => try patterns_with_len_5.append(pattern),
                    6 => try patterns_with_len_6.append(pattern),
                    else => return error.InvalidData,
                }
            }
        }

        // Prerequisites
        const bd = ~pattern_map[1] & pattern_map[4];
        const cf = pattern_map[1];
        assert(@popCount(Pattern, bd) == 2);
        assert(@popCount(Pattern, cf) == 2);

        // Find 3
        const index_3 = for (patterns_with_len_5.slice()) |x, i| {
            if (x & cf == cf) break i;
        } else return error.DidntFindThree;
        pattern_map[3] = patterns_with_len_5.swapRemove(index_3);

        // Find 5
        const index_5 = for (patterns_with_len_5.slice()) |x, i| {
            if (x & bd == bd) break i;
        } else return error.DidntFindFive;
        pattern_map[5] = patterns_with_len_5.swapRemove(index_5);

        // Find 2
        pattern_map[2] = patterns_with_len_5.swapRemove(0);

        // Find 0
        const index_0 = for (patterns_with_len_6.slice()) |x, i| {
            if (x & bd != bd) break i;
        } else return error.DidntFindZero;
        pattern_map[0] = patterns_with_len_6.swapRemove(index_0);

        // Find 9
        const index_9 = for (patterns_with_len_6.slice()) |x, i| {
            if (x & cf == cf) break i;
        } else return error.DidntFindNine;
        pattern_map[9] = patterns_with_len_6.swapRemove(index_9);

        // Find 6
        pattern_map[6] = patterns_with_len_6.swapRemove(0);

        const delimiter = iter.next() orelse return error.WrongFormat;
        if (!std.mem.eql(u8, "|", delimiter)) return error.WrongFormat;

        var value: u64 = 0;
        while (iter.next()) |raw_pattern| {
            var pattern: Pattern = 0;
            for (raw_pattern) |c| {
                pattern |= @as(Pattern, 1) << @intCast(u3, c - 'a');
            }

            const digit = for (pattern_map) |x, i| {
                if (pattern == x) break i;
            } else return error.DigitNotFound;
            value += digit;
            value *= 10;
        }

        sum += value / 10;
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
    try std.testing.expectEqual(@as(u64, 61229), count);
}
