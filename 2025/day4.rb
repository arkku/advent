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

  # @yield [coords]
  # @yieldparam coords [Coords]
  # @return [Enumerator<Coords>, self]
  def each_coords
    return enum_for(:each_coords) unless block_given?
    (0...height).each do |y|
      (0...width).each do |x|
        yield Coords.new(x: x, y: y).freeze
      end
    end
    self
  end

  # @yield [coords]
  # @yieldparam coords [Coords]
  # @return [Enumerator<Coords>, self]
  def each_roll_coords
    return enum_for(:each_roll_coords) unless block_given?
    each_coords do |coords|
      yield coords if self[coords] == '@'
    end
    self
  end

  # @param coords [Coords]
  # @yield adjacent
  # @yieldparam adjacent [Coords]
  def each_adjacent_roll_coords(coords)
    return enum_for(:each_adjacent_roll_coords, coords) unless block_given?
    coords.each_adjacent8 do |neighbour|
      adjacent = self[neighbour]
      yield neighbour if adjacent && adjacent != '.'
    end
    self
  end

  # @return [String]
  def to_s
    @map.map(&:join).join("\n")
  end
end

map = []

$stdin.each_line do |line|
  map << line.strip.chars
end

map = Map.new(map)

removable = []

map.each_roll_coords do |coords|
  if map.each_adjacent_roll_coords(coords).take(4).count < 4
    map[coords] = 'x'
    removable << coords
  end
end

puts map if map.width < 80
puts removable.count

total_removed = 0

until removable.empty?
  removable.each { |coords| map[coords] = '.' }
  total_removed += removable.count
  removable.clear

  map.each_roll_coords do |coords|
    if map.each_adjacent_roll_coords(coords).take(4).count < 4
      removable << coords
    end
  end
end

puts total_removed
