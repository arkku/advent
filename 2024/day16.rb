#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'
require 'algorithms'

class Coords
  # @return [Coords]
  def rotated_right
    if y != 0
      Coords.new(-y, 0)
    else
      Coords.new(0, x)
    end
  end

  # @return [Coords]
  def rotated_left
    if y != 0
      Coords.new(y, 0)
    else
      Coords.new(0, -x)
    end
  end

  # @return [Coords]
  def rotated_180
    Coords.new(-x, -y)
  end
end

Traversal = Struct.new(:position, :direction, :score, :path) do
  # @return [Array<Coords>]
  def vector
    [position, direction]
  end

  # @return [Array<Traversal>]
  def next_moves
    return enum_for(:next_moves) unless block_given?
    next_path = path + [vector]
    [
      [position + direction, direction, 1],
      [position, direction.rotated_left, 1000],
      [position, direction.rotated_right, 1000]
    ].each do |pos, dir, cost|
      next if path.include?([pos, dir])
      yield Traversal.new(position: pos, direction: dir, score: score + cost, path: next_path)
    end
  end

  # @return [String]
  def to_s
    "[pos: #{position}, dir: #{direction} score: #{score}]"
  end
end

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
  # @param value [String]
  # @return [String]
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

  # @param sources [Array<Traversal>]
  # @param target [Coords]
  # @param solution [Traversal, nil]
  # @return [Array(nil, Hash{Array<Coords> => Integer}), Array(Traversal, Hash{Array<Coords> => Integer})]
  def find_paths(sources:, target:, solution: nil)
    queue = Containers::MinHeap.new
    sources.each do |source|
      queue.push(source.score, source)
    end

    seen = {}

    while (move = queue.pop)
      score, vector = move.score, move.vector
      next if (seen_score = seen[vector]) && seen_score < score
      next if solution && score > solution.score

      if move.position == target
        solution ||= move
        next
      end

      move.next_moves.each do |next_move|
        next if obstacle_at?(next_move.position)

        score, vector = next_move.score, next_move.vector
        next if (seen_score = seen[vector]) && seen_score <= score

        seen[vector] = score
        queue.push(score, next_move)
      end
    end

    [solution, seen]
  end

  # @param source [Coords]
  # @param target [Coords]
  # @param best_score [Integer]
  # @param scores_from_start [Hash{Array<Coords> => Integer}]
  # @return Set<Coords>
  def tiles_on_best_paths(source:, target:, best_score:, scores_from_start:)
    best_tiles = Set.new([source, target])

    antiplayers = Coords.each_direction.map do |direction|
      Traversal.new(position: target, direction: direction, score: 0, path: Set.new)
    end

    solution, scores_from_end = find_paths(sources: antiplayers, target: source)
    solution&.path.map(&:first).each { |pos| best_tiles << pos }

    scores_from_start.each_pair do |vector_start, score_start|
      pos, dir = *vector_start
      next if best_tiles.include?(pos)

      other_dir = dir.rotated_180
      vector_end = [pos, other_dir]
      next unless (score_end = scores_from_end[vector_end])

      best_tiles << pos if score_start + score_end == best_score
    end

    best_tiles
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
player = Traversal.new(position: start_position, direction: Coords::EAST, score: 0, path: Set.new)

solution, scores_from_start = map.find_paths(sources: [player], target: finish_position)
puts solution.score

best_tiles = map.tiles_on_best_paths(source: start_position, target: finish_position, best_score: solution.score, scores_from_start: scores_from_start)
puts best_tiles.count
