const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/06.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const count = try countLanternfish(buffered_reader.reader(), 80);
    std.debug.print("number of lanternfish after 80 days: {}\n", .{count});
}

fn countLanternfish(reader: anytype, days: u64) !u64 {
    var buf: [1024]u8 = undefined;

    var fish_age_counts = [_]u64{0} ** 9;

    const line = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.MissingData;
    if ((try reader.readUntilDelimiterOrEof(&buf, '\n')) != null) return error.UnexpectedData;
    var iter = std.mem.split(u8, line, ",");
    while (iter.next()) |item| {
        const fish_age = try std.fmt.parseInt(usize, item, 10);
        if (fish_age > 8) return error.InvalidFishAge;
        fish_age_counts[fish_age] += 1;
    }

    var days_passed: u64 = 0;
    while (days_passed < days) : (days_passed += 1) {
        var new_fish_age_counts = [_]u64{0} ** 9;

        new_fish_age_counts[0] = fish_age_counts[1];
        new_fish_age_counts[1] = fish_age_counts[2];
        new_fish_age_counts[2] = fish_age_counts[3];
        new_fish_age_counts[3] = fish_age_counts[4];
        new_fish_age_counts[4] = fish_age_counts[5];
        new_fish_age_counts[5] = fish_age_counts[6];
        new_fish_age_counts[6] = fish_age_counts[7] + fish_age_counts[0];
        new_fish_age_counts[7] = fish_age_counts[8];
        new_fish_age_counts[8] = fish_age_counts[0];

        fish_age_counts = new_fish_age_counts;
    }

    var sum: u64 = 0;
    for (fish_age_counts) |x| sum += x;

    return sum;
}

test "example 1" {
    const text =
        \\3,4,3,1,2
    ;

    var fbs = std.io.fixedBufferStream(text);
    const after_18_days = try countLanternfish(fbs.reader(), 18);
    fbs = std.io.fixedBufferStream(text);
    const after_80_days = try countLanternfish(fbs.reader(), 80);
    try std.testing.expectEqual(@as(u64, 26), after_18_days);
    try std.testing.expectEqual(@as(u64, 5934), after_80_days);
}
