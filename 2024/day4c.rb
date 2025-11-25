#!/usr/bin/env ruby
# frozen_string_literal: true

word = 'MAS'.chars.freeze
middle = word[1].freeze # only words of length 3 are supported
diagonal = (word.sort - [middle]).freeze

matrix = []

$stdin.each_line do |line|
  line.strip!
  matrix << line.chars
end

xmas_count = 0
height, width = matrix.count, matrix[0].count

# The pivot char is in the middle of the word, so a match can never start
# so that the pivot is on the edge.
(1...(height - 1)).each do |y|
  (1...(width - 1)).each do |x|
    next unless matrix[y][x] == middle

    top_left = matrix[y - 1][x - 1]
    top_right = matrix[y - 1][x + 1]
    bottom_left = matrix[y + 1][x - 1]
    bottom_right = matrix[y + 1][x + 1]

    if [top_left, bottom_right].sort == diagonal && [top_right, bottom_left].sort == diagonal
      xmas_count += 1
    end
  end
end

puts xmas_count
