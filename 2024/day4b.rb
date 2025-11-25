#!/usr/bin/env ruby
# frozen_string_literal: true

WORD = 'MAS'.chars
pivot_char = WORD[WORD.count / 2]

matrix = []

$stdin.each_line do |line|
  line.strip!
  matrix << line.chars
end

xmas_count = 0
height, width = matrix.count, matrix[0].count

# @param x [Integer]
# @param y [Integer]
# @param matrix [Array<Array<String>>]
# @param dx [Integer]
# @param dy [Integer]
def is_mas(x, y, matrix, dx, dy)
  return false if dx == 0 && dy == 0
  WORD.each do |expected|
    return false unless y >= 0
    row = matrix[y]
    return false unless row && x >= 0 && row[x].to_s == expected
    x += dx
    y += dy
  end
  true
end

OFFSETS_XY = [1, -1].product([1, -1]).freeze

(0...height).each do |y|
  (0...width).each do |x|
    c = matrix[y][x]
    next unless c == pivot_char

    mas_count = 0
    OFFSETS_XY.each do |dx, dy|
      next unless is_mas(x - dx, y - dy, matrix, dx, dy)
      mas_count += 1
      if mas_count == 2
        xmas_count += 1
        break
      end
    end
  end
end

puts xmas_count
