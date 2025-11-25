#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

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

  # @param coords [Coords]
  # @return [String]
  def [](coords)
    return nil if coords.y < 0
    row = @map[coords.y]
    return nil unless row && coords.x >= 0
    row[coords.x]
  end

  # @param coords [Coords]
  # @return [Boolean]
  def obstacle_at?(coords)
    case self[coords]
    when '#', nil
      true
    else
      false
    end
  end

  # @return [String]
  def to_s
    @map.map(&:join).join("\n")
  end

  # @param source [Traversal]
  # @param target [Coords]
  # @return [Array<Coords>, nil]
  def shortest_path(source:, target:)
    queue = [ [source, []] ]
    seen = Set.new([source])

    until queue.empty?
      position, path = *queue.shift
      next_path = path + [position]
      return next_path if position == target

      Coords.each_direction do |direction|
        move = position + direction
        next if obstacle_at?(move) || seen.include?(move)
        seen << move
        queue << [move, next_path]
      end
    end

    nil
  end
end

start_position = nil
finish_position = nil

map = []

$stdin.each_line do |line|
  chars = line.strip.chars
  if (x = line.index('S'))
    start_position = Coords.new(x, map.count)
  end
  if (x = line.index('E'))
    finish_position = Coords.new(x, map.count)
  end
  map << chars
end

map = Map.new(map)
width, height = map.width, map.height
path = map.shortest_path(source: start_position, target: finish_position)

cheat_distances = [2, 20]
max_cheat_distance = cheat_distances.max
min_time_saved = map.width <= 15 ? 50 : 100

index_on_path = Array.new(width * height, -1)
path.each_with_index do |node, index|
  index_on_path[node.y * width + node.x] = index
end

cheat_counts = Array.new(cheat_distances.count, 0)

path.each_with_index do |node, index1|
  node_x, node_y = node.x, node.y
  (-max_cheat_distance).upto(max_cheat_distance) do |dy|
    y = node_y + dy
    next unless y >= 0 && y < height
    dy_abs = dy.abs
    node_offset = y * width + node_x
    remaining_cheat_distance = max_cheat_distance - dy_abs

    (-remaining_cheat_distance).upto(remaining_cheat_distance) do |dx|
      x = node_x + dx
      next unless x >= 0 && x < width
      index2 = index_on_path[node_offset + dx]
      next unless index2 > index1

      steps_skipped = index2 - index1
      distance = dx.abs + dy_abs
      time_saved = steps_skipped - distance

      next unless time_saved >= min_time_saved

      cheat_distances.each_with_index do |cheat_distance, cheat_index|
        cheat_counts[cheat_index] += distance <= cheat_distance ? 1 : 0
      end
    end
  end
end

puts cheat_counts.join("\n")
