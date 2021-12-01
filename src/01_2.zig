const std = @import("std");

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/01.txt", .{});
    defer input_file.close();

    const increases = try countIncreases(input_file.reader());
    std.debug.print("Increases: {}\n", .{increases});
}

fn readInt(reader: anytype) !?u64 {
    var buf: [16]u8 = undefined;

    return try std.fmt.parseInt(
        u64,
        (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return null,
        10,
    );
}

fn countIncreases(reader: anytype) !u64 {
    var increases: u64 = 0;
    var window = [3]u64{
        (try readInt(reader)) orelse return error.InsufficientData,
        (try readInt(reader)) orelse return error.InsufficientData,
        (try readInt(reader)) orelse return error.InsufficientData,
    };

    while (try readInt(reader)) |value| {
        const prev_sum = window[0] + window[1] + window[2];
        const sum = window[1] + window[2] + value;

        increases += @boolToInt(sum > prev_sum);

        window[0] = window[1];
        window[1] = window[2];
        window[2] = value;
    }

    return increases;
}

test "example 1" {
    const text =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
    ;

    var fbs = std.io.fixedBufferStream(text);
    try std.testing.expectEqual(@as(u64, 5), try countIncreases(fbs.reader()));
}
