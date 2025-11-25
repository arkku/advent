const std = @import("std");
const print = std.debug.print;
const log10 = std.math.log10;
const pow = std.math.pow;
const allocator = std.heap.page_allocator;
const stdout = std.io.getStdOut().writer();

var cache: std.AutoHashMap(u64, u64) = std.AutoHashMap(u64, u64).init(allocator);

fn blink(times: u64, stone: u64) u64 {
    if (times == 0) {
        return 1;
    }

    const state = (times << 56) | stone;

    if (cache.get(state)) |cached| {
        return cached;
    }

    var result: u64 = 0;

    if (stone == 0) {
        result = blink(times - 1, 1);
    } else {
        const digit_count = std.math.log10(stone) + 1;
        if (digit_count % 2 == 0) {
            const divisor = pow(u64, 10, digit_count / 2);
            result = blink(times - 1, stone / divisor) + blink(times - 1, stone % divisor);
        } else {
            result = blink(times - 1, stone * 2024);
        }
    }

    _ = cache.put(state, result) catch {};
    return result;
}

pub fn main() !void {
    var stdin = std.io.getStdIn().reader();

    const line = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024) orelse {
        return error.UnexpectedEndOfInput;
    };
    defer allocator.free(line);

    const trimmed = std.mem.trim(u8, line, " \t\n\r");
    var tokenizer = std.mem.tokenize(u8, trimmed, " ");
    var stones = std.ArrayList(u64).init(allocator);
    defer stones.deinit();

    while (tokenizer.next()) |token| {
        stones.append(try std.fmt.parseInt(u64, token, 10)) catch {
            return error.InvalidInput;
        };
    }

    const times_list = [_]u64{ 25, 75 };

    for (times_list) |times| {
        var count: u64 = 0;
        for (stones.items) |stone| {
            count += blink(times, stone);
        }
        stdout.print("{}\n", .{count}) catch {};
    }
}
