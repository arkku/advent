#!/usr/bin/env ruby
# frozen_string_literal: true

left = []
right = []
count = {}
count.default = 0

$stdin.each_line do |line|
  a, b = line.split.map(&:to_i)
  left << a
  right << b
  count[b] += 1
end

left.sort!
right.sort!

sum = 0
similarity = 0

left.zip(right) do |a, b|
  distance = a > b ? (a - b) : (b - a)
  sum += distance
  similarity += a * count[a]
end

puts sum
puts similarity
