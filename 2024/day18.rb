#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

class Map
  attr_reader :width, :height, :obstacles, :start_position, :end_position

  # @param width [Integer]
  # @param height [Integer]
  # @param obstacles [Array<Coords>]
  def initialize(width:, height:, obstacles:)
    @obstacles = {}
    obstacles.each_with_index do |obstacle, index|
      @obstacles[obstacle] = index
    end
    @width = width
    @height = height
    @start_position = Coords.new(x: 0, y: 0).freeze
    @end_position = Coords.new(x: @width - 1, y: @height - 1)
  end

  # @param coords [Coords]
  # @param time [Integer]
  # @return [Boolean]
  def obstacle_at?(coords, time:)
    return true unless coords.x >= 0 && coords.x < @width && coords.y >= 0 && coords.y < @height
    (obstacle_index = @obstacles[coords]) && obstacle_index < time
  end

  # @param source [Coords]
  # @param target [Coords]
  # @param time [Integer]
  # @return [Integer, nil]
  def find_path(source: start_position, target: end_position, time: 0)
    frontier = Set.new([source])
    visited = Set.new

    steps = 0
    until frontier.empty?
      return steps if frontier.include?(target)
      visited.merge(frontier)
      steps += 1

      frontier = frontier.each_with_object(Set.new) do |node, result|
        Coords.each_direction do |direction|
          neighbour = node + direction
          unless obstacle_at?(neighbour, time: time) || visited.include?(neighbour)
            result << neighbour
          end
        end
      end
    end
    nil
  end
end

obstacles = []
$stdin.each_line do |line|
  obstacles << line.strip.split(',').map(&:to_i)
end

obstacles.map! { |x, y| Coords.new(x: x, y: y).freeze }

is_small = obstacles.count < 1024

map = Map.new(width: is_small ? 7 : 71, height: is_small ? 7 : 71, obstacles: obstacles)
start_time = is_small ? 12 : 1024
puts map.find_path(time: start_time)

lower, upper = start_time, obstacles.count
while lower < upper
  mid = (lower + upper) / 2
  if map.find_path(time: mid)
    lower = mid + 1
  else
    upper = mid
  end
end

# we found the lowest _failing_ value, so `upper - 1` is highest succeeding
obstacle = obstacles[upper - 1]
puts "#{obstacle.x},#{obstacle.y}"
