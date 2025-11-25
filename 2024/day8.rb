#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

class Map
  # @return [Array<Coords>]
  attr_reader :antennas

  # @param array_of_rows [Array<String>]
  def initialize(array_of_rows)
    @map = array_of_rows.map(&:chars)
    @antennas_by_frequency = {}

    each_cell_with_xy do |cell, x, y|
      next unless cell =~ /^[A-Za-z0-9]$/
      antenna = Coords.new(x, y)
      on_frequency = @antennas_by_frequency[cell] || []
      on_frequency << antenna
      @antennas_by_frequency[cell] = on_frequency
    end
  end

  # @yield [frequency, antennas]
  # @yieldparam frequency [String]
  # @yieldparam antennas [Array<Coords>]
  def each_frequency_with_antennas
    @antennas_by_frequency.each_pair do |frequency, antennas|
      yield frequency, antennas
    end
    self
  end

  # @return [Array<Coords>, nil]
  def antennas_for_frequency(frequency)
    @antennas_by_frequency[frequency]
  end

  # @yield [cell, x, y]
  # @yieldparam cell [String]
  # @yieldparam x [Integer]
  # @yieldparam y [Integer]
  def each_cell_with_xy
    @map.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        yield cell, x, y
      end
    end
    self
  end

  # @return [Integer]
  def width
    @map[0].count
  end

  # @return [Integer]
  def height
    @map.count
  end

  # @return [Boolean]
  def include?(coords)
    coords.x >= 0 && coords.y >= 0 && coords.x < width && coords.y < height
  end

  # @param coords [Coords]
  # @return [String, nil]
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

map = Map.new($stdin.each_line.map(&:strip))

antinodes = Set.new
antinodes2 = Set.new
max_scale = map.width + map.height # No need for accuracy, we break early

map.each_frequency_with_antennas do |_, antennas|
  antennas.combination(2).each do |a, b|
    dx = a.x - b.x
    dy = a.y - b.y

    0.upto(max_scale) do |scale|
      p1 = Coords.new(b.x + scale * dx, b.y + scale * dy)
      p2 = Coords.new(a.x - scale * dx, a.y - scale * dy)

      in_bounds = false
      [p1, p2].each do |antinode|
        next unless map.include?(antinode)

        in_bounds = true
        antinodes2 << antinode

        if scale == 2
          # Part 1 is a subset of part 2, so we handle it here
          antinodes << antinode
          map[antinode] = '#' if map[antinode] == '.'
        else
          map[antinode] = '*' if map[antinode] == '.'
        end
      end

      break unless in_bounds # Both directions are out of bounds
    end
  end
end

puts map
puts antinodes.count
puts antinodes2.count
