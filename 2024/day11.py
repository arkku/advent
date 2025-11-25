#!/usr/bin/env python3
import math
from functools import cache

# Note: the `@cache` wrapper obscures the argument names from inline hints.

@cache
def blink(times: int, stone: int) -> int:
    if times == 0:
        return 1

    if stone == 0:
        result = blink(times - 1, 1)
    else:
        digit_count = int(math.log10(stone)) + 1
        if digit_count % 2 == 0:
            divisor = 10 ** (digit_count // 2)
            result = blink(times - 1, stone // divisor) + blink(times - 1, stone % divisor)
        else:
            result = blink(times - 1, stone * 2024)

    return result

def main() -> None:
    stones = list(map(int, input().strip().split()))
    for times in [25, 75]:
        total = 0
        for stone in stones:
            total += blink(times, stone)
        print(total)

if __name__ == "__main__":
    main()
