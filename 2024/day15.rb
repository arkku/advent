#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'
require_relative '../ui'

class Coords
  # @param c [String] A single character in `^v<>`
  # @return [Coords]
  def self.from_char(c)
    case c
    when '^'
      Coords.new(x: 0, y: -1)
    when 'v'
      Coords.new(x: 0, y: 1)
    when '<'
      Coords.new(x: -1, y: 0)
    when '>'
      Coords.new(x: 1, y: 0)
    end
  end

  # @return [Boolean]
  def vertical?
    y != 0
  end

  # @return [Coords]
  def left
    Coords.new(x: x - 1, y: y)
  end

  # @return [Coords]
  def right
    Coords.new(x: x + 1, y: y)
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

  # @return [Integer]
  def lanternfish_gps
    100 * y + x
  end
end

class Map
  # @param array_of_rows [Array<Array<String>>]
  def initialize(array_of_rows)
    @map = array_of_rows.map(&:dup)
    @cache = {}
    @cache_depends = {}
  end

  # @return [Map]
  def widened
    wide_rows = @map.map do |row|
      wide_row = []
      row.each do |c|
        case c
        when 'O', '[', ']'
          wide_row << '['
          wide_row << ']'
        when '@'
          wide_row << '@'
          wide_row << '.'
        else
          wide_row << c
          wide_row << c
        end
      end
      wide_row
    end
    Map.new(wide_rows)
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

  # @param from [Coords]
  # @param move [Coords]
  # @param perform [Boolean]
  # @return [Boolean]
  def push(from:, move:, perform: true)
    to = from + move

    case (c = self[to])
    when 'O'
      return false unless push(from: to, move: move, perform: perform)
    when '[', ']'
      if move.vertical?
        # We have to first check whether the other half can move before
        # committing to moving this half
        other_half = c == '[' ? to.right : to.left
        return false unless push(from: other_half, move: move, perform: false)
        return false unless push(from: to, move: move, perform: perform)
        push(from: other_half, move: move) if perform
      else
        return false unless push(from: to, move: move, perform: perform)
      end
    when '#'
      return false
    end

    self[to], self[from] = self[from], '.' if perform
    true
  end

  # The characters on the left side of the box (for measuring coordinates)
  BOX_LEFT_CHARS = %w(O [).freeze

  # @yield [box]
  # @yieldparam box [Coords]
  # @return [Enumerator<Coords, self>, self]
  def each_box
    return enum_for(:each_box) unless block_given?
    @map.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        yield Coords.new(x: x, y: y) if BOX_LEFT_CHARS.include?(cell)
      end
    end
    self
  end

  # @return [String]
  def to_s
    @map.map(&:join).join("\n")
  end
end

runs = []
rows = []
robot = nil

$stdin.each_line do |line|
  line.strip!
  break if line.empty?

  chars = line.chars
  if (x = line.index('@'))
    robot = Coords.new(x, rows.count)
    chars[x] = '.'
  end
  rows << chars
end

map = Map.new(rows)
runs << [map, robot]
runs << [map.widened, Coords.new(x: robot.x * 2, y: robot.y)]

moves = []
$stdin.each_line do |line|
  line.strip.chars.each do |c|
    if (move = Coords.from_char(c))
      moves << move
    end
  end
end

ui = make_ui(enabled: moves.count < 100 || ARGV.include?('-v'))

results = []

runs.each do |map, robot|
  map[robot] = '@'
  ui.frame { |output| output << map }

  i = 0
  while i < moves.count
    ui.frame do |output|
      move = moves[i]
      i += 1

      if map.push(from: robot, move: move)
        robot += move
        output << map
      end
    end
  end

  results << map.each_box.sum(&:lanternfish_gps)
  ui.split
end

ui.close

puts results.join("\n")
