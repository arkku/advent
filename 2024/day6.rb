#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

class Coords
  # @return [Coords]
  def rotated_right
    if y != 0
      Coords.new(-y, 0)
    else
      Coords.new(0, x)
    end
  end

  # @return [String]
  def char
    if y < 0
      '^'
    elsif y > 0
      'v'
    elsif x < 0
      '<'
    elsif x > 0
      '>'
    else
      '+'
    end
  end
end

Vector = Struct.new(:position, :direction) do
  # @return [Coords]
  def next_position
    position + direction
  end

  # @return [Vector]
  def moved
    Vector.new(next_position, direction)
  end

  # @return [Vector]
  def rotated_right
    Vector.new(position, direction.rotated_right)
  end

  # @return [String]
  def to_s
    "[pos: #{position}, dir: #{direction}]"
  end
end

Traversal = Struct.new(:visited_count, :path, :loop?)

class Map
  # @param array_of_rows [Array<Array<String>>]
  def initialize(array_of_rows)
    @map = array_of_rows.map(&:dup)
    @cache = {}
    @cache_depends = {}
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
  # @return [String]
  def [](coords)
    return nil if coords.y < 0
    row = @map[coords.y]
    return nil unless row && coords.x >= 0
    row[coords.x]
  end

  # @param coords [Coords]
  # @param value [String]
  # @return [String]
  def []=(coords, value)
    return if coords.y < 0 || coords.x < 0
    row = @map[coords.y]
    return unless row && coords.x < row.count
    row[coords.x] = value
  end

  # @param coords [Coords]
  # @return [Boolean]
  def obstacle_at?(coords)
    self[coords] == '#'
  end

  # @return [String]
  def to_s
    @map.map(&:join).join("\n")
  end

  # @param position [Coords]
  # @param direction [Coords]
  # @param recording [Boolean]
  # @param obstacle [Coords, nil]
  # @return [Traversal]
  def traverse(position:, direction: Coords.new(x: 0, y: -1), recording: true, obstacle: nil)
    path = []
    history = Set.new
    visited_count = 1

    if recording
      @cache = {}
      @cache_depends = {}
    end
    since_last_obstacle = 0

    while include?(position)
      entry = Vector.new(position, direction)
      if history.include?(entry)
        # Loop detected
        return Traversal.new(visited_count, path, true)
      end
      history << entry
      if recording
        path << entry

        if self[position] == '.'
          self[position] = direction.char
          visited_count += 1
        end
      end

      if obstacle && !@cache_depends[entry]&.include?(obstacle) && (cached = @cache[entry])
        # There is a cached entry that doesn't depend on the obstacle
        entry = cached
        position = entry.position
        direction = entry.direction
      end

      next_position = position + direction

      if obstacle_at?(next_position)
        direction = direction.rotated_right

        if recording
          # Populate the cache
          waypoints = path.slice(since_last_obstacle...).reverse
          dependencies = Set.new
          waypoints.each do |waypoint|
            dependencies << waypoint.position
            @cache[waypoint] = entry
            @cache_depends[waypoint] = dependencies
          end
          since_last_obstacle = path.count
        end
      else
        position = next_position
      end
    end

    Traversal.new(visited_count, path, false)
  end
end

guard_position = Coords.new(0, 0)

map = []

$stdin.each_line do |line|
  chars = line.strip.chars
  if (x = line.index('^'))
    guard_position = Coords.new(x, map.count)
  end
  map << chars
end

map = Map.new(map)
traversal = map.traverse(position: guard_position)

obstacles = Set.new
non_obstacles = Set.new
non_obstacles << guard_position

traversal.path.each do |entry|
  obstacle = entry.next_position
  next if non_obstacles.include?(obstacle) || obstacles.include?(obstacle)

  square = map[obstacle]
  next if square == '#'
  map[obstacle] = '#'

  if map.traverse(position: entry.position, direction: entry.direction, recording: false, obstacle: obstacle).loop?
    map[obstacle] = 'O'
    obstacles << obstacle
  else
    non_obstacles << obstacle
    map[obstacle] = square
  end
end

puts map if map.width < 80
puts traversal.visited_count
puts obstacles.count
