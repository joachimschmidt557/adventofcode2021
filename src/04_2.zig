const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_file = try std.fs.cwd().openFile("input/04.txt", .{});
    defer input_file.close();

    var buffered_reader = std.io.bufferedReader(input_file.reader());

    const score = try calculateWinningScore(allocator, buffered_reader.reader());
    std.debug.print("winning score: {}\n", .{score});
}

// Maps number -> position
const Board = std.AutoHashMap(u64, u64);

fn won(game_board: u25) bool {
    const winning_positions = [_]u25{
        0b11111_00000_00000_00000_00000,
        0b00000_11111_00000_00000_00000,
        0b00000_00000_11111_00000_00000,
        0b00000_00000_00000_11111_00000,
        0b00000_00000_00000_00000_11111,
        0b10000_10000_10000_10000_10000,
        0b01000_01000_01000_01000_01000,
        0b00100_00100_00100_00100_00100,
        0b00010_00010_00010_00010_00010,
        0b00001_00001_00001_00001_00001,
    };

    return for (winning_positions) |pos| {
        if (game_board & pos == pos) break true;
    } else false;
}

fn sumUnmarkedNumbers(board: Board, game_board: u25) u64 {
    var sum: u64 = 0;

    var pos: u5 = 0;
    while (pos < 25) : (pos += 1) {
        if (game_board & (@as(u25, 1) << pos) == 0) {
            var iter = board.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* == pos) {
                    sum += entry.key_ptr.*;
                }
            }
        }
    }

    return sum;
}

fn calculateWinningScore(gpa: std.mem.Allocator, reader: anytype) !u64 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf: [1024]u8 = undefined;
    var numbers_drawn = std.ArrayList(u64).init(allocator);
    var boards = std.ArrayList(Board).init(allocator);

    // Read all numbers
    {
        const line = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.MissingData;
        var iter = std.mem.split(u8, line, ",");
        while (iter.next()) |number| {
            try numbers_drawn.append(try std.fmt.parseInt(u64, number, 10));
        }
    }

    // Read all boards
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |empty_line| {
        if (empty_line.len != 0) return error.WrongFormat;
        const board = try boards.addOne();
        board.* = Board.init(allocator);

        var i: usize = 0;
        while (i < 5) : (i += 1) {
            const line = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse return error.MissingData;

            var j: usize = 0;
            var iter = std.mem.tokenize(u8, line, " ");
            while (iter.next()) |number| : (j += 1) {
                try board.put(try std.fmt.parseInt(u64, number, 10), i * 5 + j);
            }
            if (j != 5) return error.WrongFormat;
        }

        assert(board.count() == 25);
    }

    // Pick all numbers
    var game_boards = try allocator.alloc(u25, boards.items.len);
    for (game_boards) |*x| x.* = 0;
    var won_boards = try allocator.alloc(bool, boards.items.len);
    for (won_boards) |*x| x.* = false;

    for (numbers_drawn.items) |number| {
        for (boards.items) |board, i| {
            if (won_boards[i]) continue;

            if (board.get(number)) |pos| {
                game_boards[i] |= (@as(u25, 1) << @intCast(u5, pos));
            }

            if (won(game_boards[i])) {
                won_boards[i] = true;
                const number_of_boards_won = blk: {
                    var sum: usize = 0;
                    for (won_boards) |x| {
                        if (x) sum += 1;
                    }
                    break :blk sum;
                };
                if (number_of_boards_won == boards.items.len) return sumUnmarkedNumbers(board, game_boards[i]) * number;
            }
        }
    }

    return error.NoBoardWins;
}

test "example 1" {
    const text =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    ;

    var fbs = std.io.fixedBufferStream(text);
    const score = try calculateWinningScore(std.testing.allocator, fbs.reader());
    try std.testing.expectEqual(@as(u64, 1924), score);
}
