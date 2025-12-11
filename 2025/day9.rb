#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../geometry2d'

coords = $stdin.each_line.map do |line|
  Coords.from_a(line.chomp.split(',').map(&:to_i))
end.to_a

polygon = Polygon.new(points: coords)

rectangles = []
coords.each_with_index do |a, i|
  ((i + 1)...coords.length).each do |j|
    rectangles << Rectangle.new(a, coords[j])
  end
end

rectangles.sort! { |a, b| b.area <=> a.area }
puts rectangles.first.area

max_area = 0
rectangles.each do |rectangle|
  break if rectangle.area <= max_area

  max_area = rectangle.area if polygon.covers_rectangle?(rectangle)
end

puts max_area
