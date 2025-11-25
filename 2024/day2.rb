#!/usr/bin/env ruby
# frozen_string_literal: true

safe_count = 0
safe_count2 = 0

# @param levels [Array<Integer>]
# @return [Integer, nil]
def first_unsafe_index(levels)
  is_decreasing = levels[0].to_i > levels[1].to_i

  i = 0
  levels.each_cons(2) do |prev, n|
    delta = is_decreasing ? (prev - n) : (n - prev)
    return i if delta < 1 || delta > 3
    i += 1
  end

  nil
end

$stdin.each_line do |line|
  levels = line.split.map(&:to_i)
  next if levels.empty?

  unsafe_index = first_unsafe_index(levels)

  if unsafe_index.nil?
    safe_count += 1
  else
    (([0, unsafe_index - 1].max)..([levels.count, unsafe_index + 1].min)).each do |index|
      without_first_unsafe = levels[[0, (index - 2)].max...index] + levels[(index + 1)..]
      if first_unsafe_index(without_first_unsafe).nil?
        safe_count2 += 1
        break
      end
    end
  end
end

puts safe_count
puts safe_count + safe_count2
