#!/usr/bin/env ruby
# frozen_string_literal: true

@cache = {}

# @param times [Integer] The number of times to blink.
# @param stone [Integer] The initial stone.
# @return [Integer] The number of stones after all the blinks.
def blink(times, stone)
  return 1 if times == 0

  state = [times, stone]

  @cache[state] ||= begin
    times -= 1
    if stone == 0
      blink(times, 1)
    elsif (digit_count = Math.log10(stone).to_i + 1).even?
      lhs, rhs = stone.divmod(10**(digit_count / 2))
      blink(times, lhs) + blink(times, rhs)
    else
      blink(times, stone * 2024)
    end
  end
end

stones = $stdin.gets.split.map(&:to_i)

[25, 75].each do |times|
  count = stones.sum { |stone| blink(times, stone) }
  puts count
end

#puts "Cache size: #{@cache.count}"
