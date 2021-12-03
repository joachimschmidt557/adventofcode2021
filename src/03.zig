const std = @import("std");

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("input/03.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const result = try analyze(buffered_reader.reader());
    std.debug.print("gamma * epsilon: {}\n", .{result.gamma * result.epsilon});
}

const Result = struct {
    gamma: u64,
    epsilon: u64,
};

fn analyze(reader: anytype) !Result {
    var count: u64 = 0;
    var bit_counts = [1]u64{0} ** 64;
    var bit_length: u16 = undefined;
    var buf: [128]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const number = try std.fmt.parseInt(u64, line, 2);

        for (bit_counts) |*x, i| {
            x.* += (number >> @intCast(u6, i)) & 0x1;
        }
        count += 1;
        bit_length = @intCast(u16, line.len);
    }

    var gamma: u64 = 0;
    var bit_mask: u64 = 0;
    for (bit_counts) |x, i| {
        if (x > count / 2) {
            gamma |= (@as(u64, 1) << @intCast(u6, i));
        }

        if (i < bit_length) {
            bit_mask |= (@as(u64, 1) << @intCast(u6, i));
        }
    }

    const epsilon = (~gamma) & bit_mask;

    return Result{ .gamma = gamma, .epsilon = epsilon };
}

test "example 1" {
    const text =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;

    var fbs = std.io.fixedBufferStream(text);
    const result = try analyze(fbs.reader());
    try std.testing.expectEqual(@as(u64, 22), result.gamma);
    try std.testing.expectEqual(@as(u64, 9), result.epsilon);
}
