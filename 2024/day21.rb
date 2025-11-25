#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

NUMERIC_KEYPAD = %w[
  7 8 9
  4 5 6
  1 2 3
  _ 0 A
].freeze

DIRECTIONAL_KEYPAD = %w[
  _ ^ A
  < v >
].freeze

# @param keys [Array<String>]
# @param width [Integer]
# @return [Hash<String, Coords>]
def generate_positions(keys, width: 3)
  coords = {}
  keys.each_with_index do |key, i|
    coords[key] = Coords.new(x: (i % width), y: (i / width)).freeze
  end
  coords
end

NUMPAD_POSITIONS = generate_positions(NUMERIC_KEYPAD).freeze
DIRECTIONAL_POSITIONS = generate_positions(DIRECTIONAL_KEYPAD).freeze

# @param button [Coords]
# @param from [Coords]
# @param gap [Coords, nil]
# @return [Array<Array<String>>]
def possible_moves_to_press(button, from:, gap:)
  dx = (from.x - button.x).abs
  dy = (from.y - button.y).abs
  move_a = ['A']

  moves_x = Array.new(dx, button.x < from.x ? '<' : '>')
  moves_y = Array.new(dy, button.y < from.y ? '^' : 'v')

  if dy.zero?
    [moves_x + move_a]
  elsif dx.zero?
    [moves_y + move_a]
  elsif gap && (gap.x == button.x || gap.y == button.y)
    # It seems that the gap must be avoided for the result to be correct
    # (This assumes that the gap is always on a corner. Which it is.)
    result = []
    unless gap.x == button.x && gap.y == from.y
      result << moves_x + moves_y + move_a
    end
    unless gap.y == button.y && gap.x == from.x
      result << moves_y + moves_x + move_a
    end
    result
  else
    [moves_x + moves_y + move_a, moves_y + moves_x + move_a]
  end
end

# @param keys [Array<String>]
# @param key_positions [Hash<String, Coords>]
# @param index [Integer]
# @param current [String]
# @param position [Coords]
# @return [Array<Array<Array<String>>>]
def possible_moves_for_keys(keys, key_positions: NUMPAD_POSITIONS, index: 0, current: 'A', position: nil, gap: nil)
  key = keys[index]
  return [[]] unless key

  position ||= key_positions[current]
  target = key_positions[key]
  gap ||= key_positions['_']

  possible_moves_to_press(target, from: position, gap: gap).flat_map do |move|
    possible_moves_for_keys(keys, key_positions: key_positions, index: index + 1, current: key, position: target, gap: gap).map do |suffix|
      [move] + suffix
    end
  end
end

# @param keys [Array<String>]
# @param recursion [Integer]
# @param key_positions [Hash<String, Coords>]
# @param cache [Hash<String, Integer>]
# @return [Integer]
def shortest_sequence_length(keys:, recursion: 0, key_positions: NUMPAD_POSITIONS, cache: {})
  key = [keys.join, recursion, key_positions.count]
  if (cached = cache[key])
    return cached
  end

  combinations = possible_moves_for_keys(keys, key_positions: key_positions)

  result =
    if recursion.zero?
      combinations.map { |combination| combination.sum(&:length) }.min
    else
      # For caching to be effective, we need to break this down into individual
      # keys and the sum the lengths of those sub-combinations.
      combinations.map do |combination|
        combination.sum do |keys|
          shortest_sequence_length(keys: keys, recursion: recursion - 1, key_positions: DIRECTIONAL_POSITIONS, cache: cache)
        end
      end.min
    end
  cache[key] = result
end

recursion_depths = [2, 25]
checksums = Array.new(recursion_depths.count, 0)
cache = {}

$stdin.each_line do |line|
  line.strip!
  next if line.empty?

  code = line.chars.freeze
  value = line.to_i(10)

  recursion_depths.each_with_index do |recursion, index|
    length = shortest_sequence_length(keys: code, recursion: recursion, cache: cache)
    complexity = value * length
    puts "#{line} ×#{recursion} #{length} * #{value} = #{complexity}"
    checksums[index] += complexity
  end
end

puts
puts checksums.join("\n")
