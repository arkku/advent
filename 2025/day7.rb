#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

class Map
  # @param array_of_rows [Array<Array<String>>]
  def initialize(array_of_rows)
    @map = array_of_rows.map(&:dup)
  end

  # @return [Integer]
  def width
    @map[0].count
  end

  # @return [Integer]
  def height
    @map.count
  end

  # @yield row
  # @yieldparam row [[String]]
  def each_row(&block)
    @map.each(&block)
  end

  # @param coords [Coords]
  # @return [String]
  def [](coords)
    return nil if coords.y < 0
    row = @map[coords.y]
    return nil unless row && coords.x >= 0
    row[coords.x]
  end

  # @param coords [Coords]
  # @param value [String]
  def []=(coords, value)
    return if coords.y < 0 || coords.x < 0
    row = @map[coords.y]
    return unless row && coords.x < row.count
    row[coords.x] = value
  end

  # @return [String]
  def to_s
    @map.map(&:join).join("\n")
  end
end

map = []
start_position = nil

$stdin.each_line do |line|
  chars = line.strip.chars
  if (x = line.index('S'))
    start_position = Coords.new(x, map.count)
  end
  map << chars
end

map = Map.new(map)

def beam_split_count(position:, map:)
  case map[position]
  when '^'
    return 1 +
           beam_split_count(position: position + Coords::EAST, map: map) +
           beam_split_count(position: position + Coords::WEST, map: map)
  when '|'
    # Overlapping beams only count once
    return 0
  when nil
    return 0
  end

  map[position] = '|'

  beam_split_count(position: position + Coords::SOUTH, map: map)
end

split_count = beam_split_count(position: start_position, map: map)
puts map if map.width < 80 && map.height <= 50
puts split_count

# Number of ways to reach a splitter at each column
paths = Hash.new(0)
paths[start_position.x] = 1

map.each_row do |row|
  next_paths = Hash.new(0)
  paths.each do |column, count|
    if row[column] == '^'
      # Split: each fork can be reached in as many ways as the splitter
      next_paths[column - 1] += count
      next_paths[column + 1] += count
    else
      next_paths[column] += count
    end
  end
  paths = next_paths
end

puts paths.values.sum
