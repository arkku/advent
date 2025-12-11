#!/usr/bin/env ruby
# frozen_string_literal: true

Plant = Struct.new(:x, :y, :type) do
  # @return [String]
  def symbol
    type.chr
  end

  # @return [String]
  def to_s
    "(#{symbol} @ x: #{x}, y: #{y})"
  end
end

Fence = Struct.new(:x, :y, :direction) do
  # @return [Boolean]
  def horizontal?
    %i[north south].include? direction
  end

  # @param other [Fence]
  # @return [Integer]
  def <=>(other)
    if direction == other.direction
      if horizontal?
        (y - other.y).nonzero? || (x - other.x)
      else
        (x - other.x).nonzero? || (y - other.y)
      end
    else
      direction <=> other.direction
    end
  end

  # @param other [Fence]
  # @return [Boolean]
  def adjacent?(other)
    return false unless other.direction == direction

    if horizontal?
      other.y == y && (x - other.x).abs == 1
    else
      other.x == x && (y - other.y).abs == 1
    end
  end

  # @return [String]
  def to_s
    "(#{direction} x: #{x}, y: #{y})"
  end
end

class Map
  DIRECTIONS = {
    north: [0, -1],
    south: [0, 1],
    east: [1, 0],
    west: [-1, 0]
  }.freeze

  # @param array_of_rows [Array<Array<Integer>>]
  def initialize(array_of_rows)
    matrix = []
    array_of_rows.each_with_index do |row, y|
      row = row.chars if row.is_a?(String)
      x = 0
      matrix << row.map do |type|
        plant = Plant.new(x: x, y: y, type: type.ord).freeze
        x += 1
        plant
      end
    end
    @map = matrix
    @neighbours = {}
  end

  # @param region [Set<Plant>, Array<Plant>]
  # @return [Map]
  def self.from_region(region)
    return nil if region.empty?
    min_x, max_x = region.minmax_by(&:x).map(&:x)
    min_y, max_y = region.minmax_by(&:y).map(&:y)
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    row = ('.' * width).chars.map(&:ord)
    rows = ([row] * height).map(&:dup)
    region.each_with_object(Map.new(rows)) do |plant, region_map|
      region_map.insert(Plant.new(x: plant.x - min_x, y: plant.y - min_y, type: plant.type))
    end
  end

  # @yield [plant]
  # @yieldparam plant [Plant]
  def each_plant
    return enum_for(:each_plant) unless block_given?
    @map.each do |row|
      row.each do |plant|
        yield plant
      end
    end
  end

  # @param plant [Plant]
  # @return [Set<Plant>]
  def neighbours(plant)
    if (cached = @neighbours[plant])
      cached
    else
      result = Set.new
      each_neighbour(plant) { |n| result << n }
      @neighbours[plant] = result
      result
    end
  end

  # @param plant [Plant]
  # @yield [plant]
  # @yieldparam plant [Plant]
  def each_neighbour(plant)
    DIRECTIONS.each_value do |dx, dy|
      if (neighbour = self[plant.x + dx, plant.y + dy]) && neighbour.type == plant.type
        yield neighbour
      end
    end
  end

  # @param region [Set<Plant>]
  # @return Integer
  def perimeter_length(region)
    region.map { |plant| 4 - neighbours(plant).count }.sum
  end

  # @param plant [Plant]
  # @yield [fence]
  # @yieldparam fence [Fence]
  def each_fence(plant)
    DIRECTIONS.each_pair do |direction, offset|
      dx, dy = *offset
      x, y = plant.x + dx, plant.y + dy
      if self[x, y]&.type != plant.type
        yield Fence.new(x: plant.x, y: plant.y, direction: direction).freeze
      end
    end
  end

  # @param region [Set<Plant>]
  # @return [Array<Fence>]
  def perimeter_fence(region)
    result = []
    region.each do |plant|
      each_fence(plant) do |fence|
        result << fence
      end
    end
    result
  end

  # @param plant [Plant]
  # @return [Set<Plant>]
  def region_of(plant)
    frontier = Set.new([plant])
    visited = Set.new

    until frontier.empty?
      visited.merge(frontier)
      frontier = frontier.each_with_object(Set.new) do |plant, result|
        result.merge(neighbours(plant))
      end
      frontier.subtract(visited)
    end

    visited
  end

  # @return [Integer]
  def width
    @map[0].count
  end

  # @return [Integer]
  def height
    @map.count
  end

  # @param x [Integer]
  # @param y [Integer]
  # @return [Boolean]
  def include?(x, y)
    x >= 0 && y >= 0 && x < width && y < height
  end

  # @param x [Integer]
  # @param y [Integer]
  # @return [Plant, nil]
  def [](x, y)
    return nil if y < 0
    row = @map[y]
    return nil unless row && x >= 0
    row[x]
  end

  # @param plant [Plant]
  # @raise [ArgumentError] if the plant is outside the map
  def insert(plant)
    raise ArgumentError("#{plant} outside #{width}×#{height}") unless include?(plant.x, plant.y)
    @map[plant.y][plant.x] = plant.freeze
  end

  # @return [String]
  def to_s
    @map.map { |row| row.map(&:symbol).join }.join("\n")
  end
end

map = Map.new($stdin.each_line.map(&:strip))

puts map if map.width < 80

price = 0
discounted_price = 0
visited = Set.new

map.each_plant do |plant|
  next if visited.include? plant

  region = map.region_of(plant)
  visited.merge(region)

  area = region.count
  perimeter_fence = map.perimeter_fence(region).sort
  perimeter_length = perimeter_fence.count
  sides = perimeter_fence.chunk_while { |a, b| a.adjacent?(b) }.map(&:first).to_a

  price += area * perimeter_length
  discounted_price += area * sides.count

  if map.width < 20
    puts ''
    region_map = Map.from_region(region)
    puts "#{plant} area=#{area} perimeter=#{perimeter_length} sides=#{sides.count} width=#{region_map.width} height=#{region_map.height}"
    puts region_map
  end
end

puts price
puts discounted_price
