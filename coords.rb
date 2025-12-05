# frozen_string_literal: true

Coords = Struct.new(:x, :y) do
  # @return [Boolean]
  def zero?
    x.zero? && y.zero?
  end

  # @return [self, Boolean]
  def nonzero?
    x.nonzero? || y.nonzero? ? self : false
  end

  # @return [self, Boolean]
  def integer?
    (x % 1).zero? && (y % 1).zero? ? self : false
  end

  # @param other [Coords]
  # @return [Coords]
  def +(other)
    Coords.new(x + other.x, y + other.y).freeze
  end

  # @param other [Coords]
  # @return [Coords]
  def -(other)
    Coords.new(x - other.x, y - other.y).freeze
  end

  # @param other [Coords, Numeric]
  # @return [Coords]
  def *(other)
    if other.is_a?(Coords)
      Coords.new(x * other.x, y * other.y).freeze
    else
      Coords.new(x * other, y * other).freeze
    end
  end

  # @param other [Coords, Numeric]
  # @return [Coords]
  def /(other)
    if other.is_a?(Coords)
      Coords.new(x / other.x, y / other.y).freeze
    else
      Coords.new(x / other, y / other).freeze
    end
  end

  # @param other [Coords, Numeric]
  # @return [Coords]
  def %(other)
    if other.is_a?(Coords)
      Coords.new(x % other.x, y % other.y).freeze
    else
      Coords.new(x % other, y % other).freeze
    end
  end

  # @param other [Coords]
  # @return [Integer,Boolean]
  def factor_of?(other)
    xmod = x.nonzero? ? (other.x % x) : other.x
    ymod = y.nonzero? ? (other.y % y) : other.y
    return false unless xmod.zero? && ymod.zero? && nonzero?
    if x.zero?
      other.x.zero? ? other.y / y : false
    elsif y.zero?
      other.y.zero? ? other.x / x : false
    else
      factor = other / self
      factor.x == factor.y ? factor.x : false
    end
  end

  # @param other [Coords]
  # @return [Boolean]
  def colinear?(other)
    x * other.y == y * other.x
  end

  # @param other [Coords]
  # @return [Integer]
  def distance(other)
    (x - other.x).abs + (y - other.y).abs
  end

  # @return [Array<Numeric>]
  def to_a
    [x, y]
  end

  # @return [Coords]
  def to_f
    Coords.new(x: x.to_f, y: y.to_f).freeze
  end

  # @return [Coords]
  def to_i
    Coords.new(x: x.to_i, y: y.to_i).freeze
  end

  # @return [String]
  def to_s
    "(#{x},#{y})"
  end
end

class Coords
  ZERO = Coords.new(x: 0, y: 0).freeze
  NORTH = Coords.new(x: 0, y: -1).freeze
  SOUTH = Coords.new(x: 0, y: 1).freeze
  EAST = Coords.new(x: 1, y: 0).freeze
  WEST = Coords.new(x: -1, y: 0).freeze

  NORTHEAST = Coords.new(x: 1, y: -1).freeze
  SOUTHEAST = Coords.new(x: 1, y: 1).freeze
  SOUTHWEST = Coords.new(x: -1, y: 1).freeze
  NORTHWEST = Coords.new(x: -1, y: -1).freeze

  DIRECTIONS = [NORTH, SOUTH, EAST, WEST].freeze
  DIRECTIONS8 = (DIRECTIONS + [NORTHEAST, SOUTHEAST, SOUTHWEST, NORTHWEST]).freeze

  # @return [Coords]
  def self.zero
    ZERO
  end

  def self.each_direction(&block)
    return DIRECTIONS.enum_for(:each) unless block_given?
    DIRECTIONS.each(&block)
  end

  def self.each_direction8(&block)
    return DIRECTIONS8.enum_for(:each) unless block_given?
    DIRECTIONS8.each(&block)
  end

  def each_adjacent
    return enum_for(:each_adjacent) unless block_given?
    DIRECTIONS.each do |direction|
      yield self + direction
    end
    self
  end

  def each_adjacent8
    return enum_for(:each_adjacent8) unless block_given?
    DIRECTIONS8.each do |direction|
      yield self + direction
    end
    self
  end
end
