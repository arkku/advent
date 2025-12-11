# frozen_string_literal: true

require_relative 'coords'

class Edge
  # @return [Point]
  attr_reader :a, :b

  # @return [Point]
  attr_reader :min, :max

  # @param a [Point]
  # @param b [Point]
  def initialize(a, b)
    @a = a
    @b = b
    min_x, max_x = [a.x, b.x].minmax
    min_y, max_y = [a.y, b.y].minmax
    @min = Coords.new(x: min_x, y: min_y).freeze
    @max = Coords.new(x: max_x, y: max_y).freeze
  end

  # @return [Boolean]
  def vertical?
    @a.x == @b.x
  end

  # @return [Boolean]
  def horizontal?
    @a.y == @b.y
  end

  # @param other [Edge]
  # @return [Boolean]
  def crosses?(other)
    if horizontal?
      other.vertical? &&
        @min.y > other.min.y &&
        @min.y < other.max.y &&
        @max.x > other.min.x &&
        @min.x < other.max.x
    elsif vertical?
      other.horizontal? &&
        @min.x > other.min.x &&
        @min.x < other.max.x &&
        @max.y > other.min.y &&
        @min.y < other.max.y
    else
      raise "Diagonal edges not supported"
    end
  end

  # @param point [Coords]
  # @return [Boolean]
  def contains_point?(point)
    point.x >= min.x && point.x <= max.x && point.y >= min.y && point.y <= max.y
  end

  # @return [String]
  def to_s
    "(#{@a} - #{@b})"
  end
end

class Polygon
  # @return [Array<Coords>]
  attr_reader :points

  # @return [Coords]
  attr_reader :min, :max

  # @param points [Array<Coords>]
  def initialize(points:)
    @points = points.freeze
    min_x, max_x = points.map(&:x).minmax
    min_y, max_y = points.map(&:y).minmax
    @min = Coords.new(x: min_x, y: min_y).freeze
    @max = Coords.new(x: max_x, y: max_y).freeze
  end

  # @return [Array<Edge>]
  def edges
    @edges ||= points.each_with_index.map do |point, i|
      Edge.new(point, points[(i + 1) % points.count]).freeze
    end.freeze
  end

  # @param point [Coords]
  def contains_point?(point)
    inside = false

    edges.each do |edge|
      return true if edge.contains_point? point

      a, b = edge.a, edge.b

      # NOTE: I believe there is a theoretical division by zero here
      # when using integer coordinates, but it will not occur in the
      # Advent of Code input, so leaving it as unhandled.

      if ((a.y > point.y) != (b.y > point.y)) &&
         point.x < ((a.x - b.x) * (point.y - b.y) / (a.y - b.y) + b.x)
        inside = !inside
      end
    end

    inside
  end

  # Is the given rectangle is fully covered by this polygon, i.e., no part of
  # the rectangle is outside the polygon.
  # @note Complicated polygons may give incorrect results.
  # @param rectangle [Rectangle]
  # @return [Boolean]
  def covers_rectangle?(rectangle)
    # All corners must be inside the polygon
    return false unless rectangle.corners.all? { |corner| contains_point?(corner) }

    # There must be no edge crossings
    rectangle.edges.none? { |other| edges.any? { |edge| edge.crosses?(other) } }
  end

  # Is the other polygon is fully covered by this polygon?
  # @note Complicated polygons may give incorrect results.
  # @param other [Polygon]
  # @return [Boolean]
  def covers_polygon?(other)
    return false unless other.points.all? { |point| contains_point?(point) }
    other.edges.none? { |theirs| edges.any? { |ours| ours.crosses?(theirs) } }
  end

  # @return [String]
  def to_s
    @points.map(&:to_s).join("\n")
  end

  # @return [String]
  def inspect
    "Polygon(#{@points.count} points, #{@min} - #{@max})"
  end
end

class Rectangle
  # @return [Coords]
  attr_reader :min, :max

  # @return [Numeric]
  attr_reader :area

  # A Rectangle defined by its two opposite corners.
  # @param a [Coords]
  # @param b [Coords]
  def initialize(a, b)
    xs = [a.x, b.x]
    ys = [a.y, b.y]
    @min = Coords.new(x: xs.min, y: ys.min).freeze
    @max = Coords.new(x: xs.max, y: ys.max).freeze
    @area = (@max.x - @min.x + 1) * (@max.y - @min.y + 1)
  end

  # @return [Array<Coords>]
  def corners
    @corners ||= [
      @min,
      Coords.new(x: @min.x, y: @max.y).freeze,
      @max,
      Coords.new(x: @max.x, y: @min.y).freeze
    ]
  end

  # @return [Array<Edge>]
  def edges
    @edges ||= begin
      c = corners
      [
        Edge.new(c[0], c[1]).freeze,
        Edge.new(c[1], c[2]).freeze,
        Edge.new(c[2], c[3]).freeze,
        Edge.new(c[3], c[0]).freeze
      ].freeze
    end
  end

  # @return [Polygon]
  def to_polygon
    Polygon.new(points: corners)
  end

  # @return [String]
  def to_s
    "[#{min} -> #{max}]"
  end

  # @return [String]
  def inspect
    "Rectangle(#{min} -> #{max})"
  end
end
