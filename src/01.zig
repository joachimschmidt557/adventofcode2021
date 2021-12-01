const std = @import("std");

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/01.txt", .{});
    defer input_file.close();

    const increases = try countIncreases(input_file.reader());
    std.debug.print("Increases: {}\n", .{increases});
}

fn countIncreases(reader: anytype) !u64 {
    var increases: u64 = 0;
    var buf: [16]u8 = undefined;
    var prev_value = try std.fmt.parseInt(
        u64,
        (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.NoData,
        10,
    );

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const value = try std.fmt.parseInt(u64, line, 10);
        increases += @boolToInt(value > prev_value);
        prev_value = value;
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
    try std.testing.expectEqual(@as(u64, 7), try countIncreases(fbs.reader()));
}
