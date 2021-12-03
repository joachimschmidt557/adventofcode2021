const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/03.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const result = try analyze(allocator, buffered_reader.reader());
    std.debug.print(
        "oxgen generator rating * CO2 generator rating: {}\n",
        .{result.o2_generator_rating * result.co2_scrubber_rating},
    );
}

const Result = struct {
    o2_generator_rating: u64,
    co2_scrubber_rating: u64,
};

fn analyze(allocator: std.mem.Allocator, reader: anytype) !Result {
    var buf: [128]u8 = undefined;
    var bit_length: u6 = 0;
    var o2_numbers = std.ArrayList(u64).init(allocator);
    defer o2_numbers.deinit();

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const number = try std.fmt.parseInt(u64, line, 2);
        try o2_numbers.append(number);
        bit_length = @intCast(u6, line.len);
    }

    var co2_numbers = std.ArrayList(u64).fromOwnedSlice(allocator, try allocator.dupe(u64, o2_numbers.items));
    defer co2_numbers.deinit();

    {
        var i = bit_length - 1;
        while (o2_numbers.items.len > 1) {
            var count_ones: usize = 0;
            for (o2_numbers.items) |x| {
                if (((x >> i) & 0x1) == 0x1) count_ones += 1;
            }

            const filter_out: u64 = if (2 * count_ones == o2_numbers.items.len or count_ones > o2_numbers.items.len / 2) 0x0 else 0x1;
            var j: isize = 0;
            while (j < o2_numbers.items.len) : (j += 1) {
                if ((o2_numbers.items[@intCast(usize, j)] >> i) & 0x1 == filter_out) {
                    _ = o2_numbers.swapRemove(@intCast(usize, j));
                    j -= 1;
                }
            }

            if (o2_numbers.items.len > 1) i -= 1;
        }
    }

    {
        var i = bit_length - 1;
        while (co2_numbers.items.len > 1) {
            var count_ones: usize = 0;
            for (co2_numbers.items) |x| {
                if (((x >> i) & 0x1) == 0x1) count_ones += 1;
            }

            const filter_out: u64 = if (2 * count_ones == co2_numbers.items.len or count_ones > co2_numbers.items.len / 2) 0x1 else 0x0;
            var j: isize = 0;
            while (j < co2_numbers.items.len) : (j += 1) {
                if ((co2_numbers.items[@intCast(usize, j)] >> i) & 0x1 == filter_out) {
                    _ = co2_numbers.swapRemove(@intCast(usize, j));
                    j -= 1;
                }
            }

            if (co2_numbers.items.len > 1) i -= 1;
        }
    }

    return Result{
        .o2_generator_rating = o2_numbers.items[0],
        .co2_scrubber_rating = co2_numbers.items[0],
    };
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
    const result = try analyze(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 23), result.o2_generator_rating);
    try std.testing.expectEqual(@as(u64, 10), result.co2_scrubber_rating);
}
