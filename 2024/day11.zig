const std = @import("std");
const log10 = std.math.log10;
const pow = std.math.pow;
const allocator = std.heap.page_allocator;

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
        const digit_count = log10(stone) + 1;
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
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    const stdin = std.fs.File.stdin();
    var stdin_reader = stdin.reader(&stdin_buffer);
    const reader = &stdin_reader.interface;

    var stones = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer stones.deinit(allocator);

    while (reader.takeDelimiterExclusive('\n')) |line| {
        if (line.len == 0) break;

        var fields = std.mem.tokenizeAny(u8, line, " \t\r");
        while (fields.next()) |field| {
            const stone = try std.fmt.parseInt(u64, field, 10);
            try stones.append(allocator, stone);
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => { 
            std.log.err("Error: {}\n", .{err});
            return err;
        }
    }

    const times_list = [_]u64{ 25, 75 };

    for (times_list) |times| {
        var count: u64 = 0;
        for (stones.items) |stone| {
            count += blink(times, stone);
        }
        try stdout.print("{}\n", .{count});
        try stdout.flush();
    }
}
