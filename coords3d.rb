# frozen_string_literal: true

Coords3D = Struct.new(:x, :y, :z) do
  # @param fields [Array(Numeric, Numeric, Numeric)]
  # @return [self]
  def self.from_a(fields)
    new(x: fields[0], y: fields[1], z: fields[2]).freeze
  end

  # @param other [Coords3D]
  # @return [Numeric]
  def distance_to(other)
    Math.hypot(x - other.x, y - other.y, z - other.z)
  end

  # @param other [Coords3D]
  # @return [Numeric]
  def squared_distance(other)
    dx = x - other.x
    dy = y - other.y
    dz = z - other.z
    dx * dx + dy * dy + dz * dz
  end

  # @return [Array(Numeric, Numeric, Numeric)]
  def to_a
    [x, y, z]
  end

  # @return [Coords3D]
  def to_f
    Coords.new(x: x.to_f, y: y.to_f, z: z.to_f).freeze
  end

  # @return [Coords3D]
  def to_i
    Coords.new(x: x.to_i, y: y.to_i, z: z.to_i).freeze
  end

  # @return [String]
  def to_s
    "(#{x},#{y},#{z})"
  end
end

class Coords3D
  ZERO = Coords3D.new(x: 0, y: 0, z: 0).freeze

  # @return [Coords3D]
  def self.zero
    ZERO
  end
end
