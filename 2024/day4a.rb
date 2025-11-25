#!/usr/bin/env ruby
# frozen_string_literal: true

WORD = 'XMAS'.chars.freeze

matrix = []
check_matrix = []

$stdin.each_line do |line|
  line.strip!
  matrix << line.chars
  check_matrix << line.gsub(/./, '.').chars
end

xmas_count = 0
height, width = matrix.count, matrix[0].count

# @param x [Integer]
# @param y [Integer]
# @param matrix [Array<Array<String>>]
# @param dx [Integer]
# @param dy [Integer]
def is_xmas(x, y, matrix, dx, dy)
  WORD.each do |expected|
    return false unless y >= 0
    row = matrix[y]
    return false unless row && x >= 0 && row[x].to_s == expected
    x += dx
    y += dy
  end
  true
end

# @param x [Integer]
# @param y [Integer]
# @param matrix [Array<Array<String>>]
# @param dx [Integer]
# @param dy [Integer]
def mark_xmas(x, y, matrix, dx, dy)
  WORD.each do |char|
    matrix[y][x] = char
    x += dx
    y += dy
  end
end

OFFSETS = [0, 1, -1].freeze
OFFSETS_XY = OFFSETS.product(OFFSETS)[1..].freeze

output_enabled = width < 40

(0...height).each do |y|
  (0...width).each do |x|
    c = matrix[y][x]
    next unless c == WORD[0]

    OFFSETS_XY.each do |dx, dy|
      if is_xmas(x, y, matrix, dx, dy)
        xmas_count += 1
        mark_xmas(x, y, check_matrix, dx, dy) if output_enabled
      end
    end
  end
end

if output_enabled
  check_matrix.each do |row|
    puts row.join
  end
end

puts xmas_count
