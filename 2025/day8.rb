#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords3d'

coords = $stdin.each_line.map do |line|
  Coords3D.from_a(line.chomp.split(',').map(&:to_i))
end.to_a

# @param coords [Array<Coords3D>]
# @return [Array(Integer, Integer)] Array of pairs of indexes in `coords`.
def edges_sorted_by_distance(coords:)
  edges = []

  coords.each_with_index do |a, i|
    ((i + 1)...coords.length).each do |j|
      b = coords[j]
      edges << [a.squared_distance(b), i, j]
    end
  end

  edges.sort_by!(&:first)
  edges.map! { |_, i, j| [i, j] }
end

# @param root [Integer]
# @param neighbours [Hash{Integer => Set<Integer>}]
# @return [Set<Integer>]
def connected_component(root:, neighbours:)
  frontier = Set.new([root])
  visited = Set.new

  until frontier.empty?
    visited.merge(frontier)
    next_frontier = Set.new
    frontier.each do |node|
      next_frontier.merge(neighbours[node])
    end
    next_frontier.subtract(visited)
    frontier = next_frontier
  end

  visited
end

link_count = coords.count < 30 ? 10 : 1000

edges = edges_sorted_by_distance(coords: coords)

shortest_edges = edges.take(link_count)
neighbours = Hash.new { Set.new }
shortest_edges.each do |a, b|
  neighbours[a] += [b]
  neighbours[b] += [a]
end

# Find connected components

remaining_nodes = Set.new((0...coords.count).to_a)
components = []

until remaining_nodes.empty?
  component = connected_component(root: remaining_nodes.first, neighbours: neighbours)
  remaining_nodes.subtract(component)
  components << component
end

puts components.map(&:count).max(3).inject(1, &:*)

# Part 2: Add more edges one by one until the entire graph is one component

component_of_node = {}
component_by_id = {}

components.each_with_index do |component, index|
  component_by_id[index] = component
  component.each { |node| component_of_node[node] = index }
end

remaining_edges = edges.drop(link_count).reverse

while (a, b = remaining_edges.pop)
  ac = component_of_node[a]
  bc = component_of_node[b]
  next if ac == bc

  # The edge merged two components, renumber the one with fewer nodes

  a_nodes = component_by_id[ac]
  b_nodes = component_by_id[bc]

  if a_nodes.count < b_nodes.count
    a_nodes.each { |node| component_of_node[node] = bc }
    component_by_id[bc].merge(component_by_id.delete(ac))
  else
    b_nodes.each { |node| component_of_node[node] = ac }
    component_by_id[ac].merge(component_by_id.delete(bc))
  end

  if component_by_id.count == 1
    # Only one component remains, done
    puts coords[a].x * coords[b].x
    break
  end
end
