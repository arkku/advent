#!/usr/bin/env crystal run

class RNG
  @state : UInt64
  @mod : UInt64

  getter state

  def initialize(secret : UInt64, mod : UInt64 = 16777216)
    @state = secret
    @mod = mod
  end

  def next : UInt64
    @state = ((@state << 6) ^ @state) % @mod
    @state = ((@state >> 5) ^ @state) % @mod
    @state = ((@state << 11) ^ @state) % @mod
  end
end

secrets = STDIN.each_line.map(&.strip.to_u64)

sum_of_2000th = 0_u64
total_per_pattern = Hash(UInt32, UInt32).new(0)

secrets.each do |secret|
  rng = RNG.new(secret: secret)

  previous = 0_i8
  pattern = 0_u32
  patterns = Hash(UInt32, Int8).new

  2000.times do |n|
    price = (rng.next % 10).to_i8
    change = (price - previous)
    pattern <<= 8
    pattern |= change + 10 # Avoid negative values
    patterns[pattern] ||= price if n >= 3
    previous = price
  end

  patterns.each do |pattern, price|
    total_per_pattern[pattern] += price
  end

  sum_of_2000th += rng.state
end

puts sum_of_2000th
puts total_per_pattern.values.max
