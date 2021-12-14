const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/14.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try performPolymerization(allocator, buffered_reader.reader(), 40);
    std.debug.print("quantity of most common element - quantity of least common element: {}\n", .{count});
}

const Rule = struct { condition: [2]u8, insert: u8 };
const num_letters: usize = 'Z' - 'A' + 1;

fn asciiNumber(x: u8) u8 {
    return x - 'A';
}

fn performPolymerization(gpa: std.mem.Allocator, reader: anytype, steps: u64) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [4096]u8 = undefined;
    var rules = std.ArrayList(Rule).init(allocator);

    const template = try allocator.dupe(u8, (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.UnexpectedEOF);
    if (template.len < 2) return error.TemplateTooSmall;
    if (((try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.UnexpectedEOF).len > 0) return error.WrongFormat;
    _ = template;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len != 7) return error.WrongFormat;
        if (!std.mem.eql(u8, " -> ", line[2..6])) return error.WrongFormat;

        try rules.append(.{
            .condition = line[0..2].*,
            .insert = line[6],
        });
    }

    // pairs is basically a 2D matrix indexed via ['A']['B'] for a
    // pair AB
    var pairs = try allocator.alloc(u64, num_letters * num_letters);
    std.mem.set(u64, pairs, 0);
    var last_pair: [2]u8 = template[template.len - 2 ..][0..2].*;

    // populate pairs with initial template
    {
        var i: u64 = 0;
        while (i + 1 < template.len) : (i += 1) {
            pairs[asciiNumber(template[i]) + asciiNumber(template[i + 1]) * num_letters] += 1;
        }
    }

    // do steps
    {
        var tmp_pairs = try allocator.alloc(u64, num_letters * num_letters);
        var tmp_last_pair: [2]u8 = undefined;
        var i: u64 = 0;
        while (i < steps) : (i += 1) {
            std.mem.copy(u64, tmp_pairs, pairs);
            std.mem.copy(u8, &tmp_last_pair, &last_pair);

            for (rules.items) |rule| {
                const left = asciiNumber(rule.condition[0]);
                const right = asciiNumber(rule.condition[1]);
                const middle = asciiNumber(rule.insert);

                const num_matching_pairs = pairs[left + right * num_letters];

                tmp_pairs[left + right * num_letters] -= num_matching_pairs;
                tmp_pairs[left + middle * num_letters] += num_matching_pairs;
                tmp_pairs[middle + right * num_letters] += num_matching_pairs;

                if (std.mem.eql(u8, &rule.condition, &last_pair)) {
                    tmp_last_pair[0] = rule.insert;
                }
            }

            std.mem.copy(u64, pairs, tmp_pairs);
            std.mem.copy(u8, &last_pair, &tmp_last_pair);
        }
    }

    var histogram = [_]u64{0} ** num_letters;

    // calculate histogram
    {
        var i: u64 = 0;
        while (i < num_letters) : (i += 1) {
            var j: u64 = 0;
            while (j < num_letters) : (j += 1) {
                histogram[i] += pairs[i + j * num_letters];
            }
        }

        histogram[asciiNumber(last_pair[1])] += 1;
    }

    // std.debug.print("last pair: {s}\n", .{&last_pair});
    // std.debug.print("histogram: {any}\n", .{histogram});

    const max = std.mem.max(u64, &histogram);
    const min = blk: {
        var min: ?u64 = null;
        for (histogram) |x| {
            if (x > 0) {
                if (min) |current_min| {
                    min = std.math.min(current_min, x);
                } else {
                    min = x;
                }
            }
        }
        break :blk min.?; // no minimum found
    };

    return max - min;
}

test "example 1" {
    const text =
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    ;

    var fbs = std.io.fixedBufferStream(text);
    const count = try performPolymerization(std.testing.allocator, fbs.reader(), 40);
    try std.testing.expectEqual(@as(u64, 2188189693529), count);
}
