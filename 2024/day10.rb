#!/usr/bin/env ruby
# frozen_string_literal: true

Node = Struct.new(:x, :y, :height) do
  # @return [String]
  def to_s
    "(#{height} x: #{x}, y: #{y})"
  end
end

class Map
  # @param array_of_rows [Array<Array<Integer>>]
  def initialize(array_of_rows)
    matrix = []
    array_of_rows.each_with_index do |row, y|
      x = 0
      matrix << row.map do |height|
        node = Node.new(x: x, y: y, height: height)
        x += 1
        node
      end
    end
    @map = matrix
    @neighbours = {}
  end

  # @yield [node]
  # @yieldparam node [Node]
  # @return [Enumerator<Node>, self]
  def each_node
    return enum_for(:each_node) unless block_given?
    @map.each do |row|
      row.each do |node|
        yield node
      end
    end
    self
  end

  # @param node [Node]
  # @return [Set<Node>]
  def neighbours(node)
    if (cached = @neighbours[node])
      cached
    else
      result = Set.new
      each_neighbour(node) { |n| result << n }
      @neighbours[node] = result
      result
    end
  end

  # @param node [Node]
  # @yield [node]
  # @yieldparam node [Node]
  def each_neighbour(node)
    target_height = node.height + 1
    [
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ].each do |dx, dy|
      if (neighbour = self[node.x + dx, node.y + dy]) && neighbour.height == target_height
        yield neighbour
      end
    end
  end

  # @param node [Node]
  # @return [Set<Node>]
  def reachable_from(node)
    frontier = Set.new([node])
    visited = Set.new

    until frontier.empty?
      visited.merge(frontier)
      frontier = frontier.each_with_object(Set.new) do |node, result|
        result.merge(neighbours(node))
      end
      frontier.subtract(visited)
    end

    visited
  end

  # NOTE: The "paths" are Sets of Nodes – order doesn't matter for this purpose
  # @param start_node [Node]
  # @param end_nodes [Set<Node>]
  # @return [Array<Set<Node>>]
  def all_paths(start_node:, end_nodes:)
    result = []
    search = [ [start_node, Set.new([start_node])] ]

    until search.empty?
      node, path = search.pop

      if end_nodes.include?(node)
        result << path
        next
      end

      neighbours(node).each do |neighbour|
        next if path.include?(neighbour)
        search << [neighbour, path.dup.add(neighbour)]
      end
    end

    result
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
  # @return [Node, nil]
  def [](x, y)
    return nil if y < 0
    row = @map[y]
    return nil unless row && x >= 0
    row[x]
  end

  # @return [String]
  def to_s
    @map.map { |row| row.map(&:height).join }.join("\n")
  end
end

map = []

$stdin.each_line do |line|
  map << line.strip.chars.map(&:to_i)
end
map = Map.new(map)

start_nodes = Set.new
end_nodes = Set.new

map.each_node do |node|
  case node.height
  when 0
    start_nodes << node
  when 9
    end_nodes << node
  end
end

sum = 0
sum_of_ratings = 0

start_nodes.each do |node|
  paths = map.all_paths(start_node: node, end_nodes: end_nodes)
  sum_of_ratings += paths.count
  reachable = paths.each_with_object(Set.new) { |path, union| union.merge(path) }.intersection(end_nodes)
  sum += reachable.count
end

puts sum
puts sum_of_ratings
