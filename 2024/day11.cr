#!/usr/bin/env crystal run
def blink(times : Int8, stone : Int64, cache : Hash(Int64, Int64)) : Int64
  return 1_i64 if times == 0

  state = (times.to_i64 << 56) | stone

  cache[state] ||= begin
    times -= 1
    if stone == 0
      blink(times, 1, cache)
    elsif (digit_count = Math.log10(stone.to_f).to_i32 + 1).even?
      lhs, rhs = stone.divmod(10**(digit_count / 2).to_i64)
      blink(times, lhs, cache) + blink(times, rhs, cache)
    else
      blink(times, stone * 2024, cache)
    end
  end
end

stones = (gets || "").split.map(&.to_i64)

cache = Hash(Int64, Int64).new

[25_i8, 75_i8].each do |times|
  count : Int64 = stones.sum { |stone| blink(times, stone, cache) }
  puts count
end
