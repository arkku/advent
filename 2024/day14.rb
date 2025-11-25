#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

use_the_brute_force = ARGV.include?('-v') || ARGV.include?('-u')

class Rendering
  # @param map [Bathroom]
  # @param robots [Array<Robot>]
  def initialize(map:, robots:)
    @width = map.width
    @height = map.height
    @robots = robots
    row = "#{'.' * map.width}\n"
    @string = "#{row * map.height}\n"
  end

  def to_s
    map = @string.dup
    @robots.each do |robot|
      map[robot.position.y * (@width + 1) + robot.position.x] = '@'
    end
    map
  end
end

class Bathroom
  attr_reader :width, :height

  # @param width [Integer]
  # @param height [Integer]
  def initialize(width:, height:)
    @width = width
    @height = height
  end

  # @param position [Coords]
  def quadrant(position:)
    qx = width / 2 - position.x
    qy = height / 2 - position.y
    return nil if qx.zero? || qy.zero?
    Coords.new(x: qx.negative? ? 1 : 0, y: qy.negative? ? 1 : 0).freeze
  end

  # @param robots [Array<Robot>]
  def safety_factor(robots:)
    quadrant_count = {}
    quadrant_count.default = 0
    robots.each do |robot|
      if (q = quadrant(position: robot.position))
        quadrant_count[q] += 1
      end
    end
    result = 1
    quadrant_count.each_value { |count| result *= count }
    result
  end
end

Robot = Struct.new(:position, :velocity) do
  # @param line [String]
  def self.from_string(line)
    raise ArgumentError(line) unless line =~ /^p=/
    _, px, py, vx, vy = line.strip.split(/[pv=, ]+/).map(&:to_i)
    Robot.new(position: Coords.new(x: px, y: py), velocity: Coords.new(x: vx, y: vy).freeze)
  end

  # @param map [Bathroom]
  # @param seconds [Integer]
  def move(map:, seconds: 1)
    position.x = (position.x + velocity.x * seconds) % map.width
    position.y = (position.y + velocity.y * seconds) % map.height
    self
  end

  def to_s
    "[p=#{position} v=#{velocity}]"
  end
end

part1_seconds = 100
robots = $stdin.each_line.map { |line| Robot.from_string(line) }.to_a
is_small = robots.count <= 20
bathroom = Bathroom.new(width: is_small ? 11 : 101, height: is_small ? 7 : 103)

x_max = { value: 0, second: 0 }
y_max = x_max.dup
seconds_to_run = [bathroom.width, bathroom.height, part1_seconds].max

(1..seconds_to_run).each do |second|
  x_count = {}
  x_count.default = 0
  y_count = x_count.dup

  robots.each do |robot|
    robot.move(map: bathroom)
    x_count[robot.position.x] += 1
    y_count[robot.position.y] += 1
  end

  [[x_max, x_count], [y_max, y_count]].each do |axis_max, axis_count|
    most_on_axis = axis_count.values.max
    if most_on_axis > axis_max[:value]
      axis_max[:value] = most_on_axis
      axis_max[:second] = second
    end
  end

  puts bathroom.safety_factor(robots: robots) if second == part1_seconds
end

exit 0 if is_small

# Since the x and y positions are modulo width/height, and the width
# and height are conspicuously prime numbers, the x coordinates will repeat
# on a cycle of 101 and the y coordinates will repeat on a cycle of 103.
#
# Above we have calculated `x_max` and `y_sec` to find the two "frames"
# with the most robots on the same coordinate on each axis. These are the
# first frames where the robots are in the Christmas tree position, but
# only on one axis! The frame where the actual Christmas tree formation
# takes place is one where both of these cycles coincide.
#
# A brute force solution is to keep adding 101 to the x-alignment frame
# number and 103 to the y-alignment frame number until we get the same
# number for both.
#
# However, stealing some advanced math ideas from Reddit solutions and
# applying them to my alignment detection:
#
# Using what is called Chinese Remainder Theorem, if we know the
# remainder (i.e., the x or y coordinate) from dividing by multiple smaller
# numbers, we can calculate the number being divided. Here, the smaller
# dividers are the width and height, and the number being divided is the
# second (frame) at which the tree occurs.
#
#          tree_sec = x_sec (mod width)     ->
#          tree_sec = x_sec + k * width     (for some loop number k)
#
#          tree_sec = y_sec (mod height)    -> (substituting tree_sec)
# x_sec + k * width = y_sec (mod height)
#         k * width = y_sec - x_sec (mod height)
#                 k = inverse(width) * (y_sec - x_sec) (mod height)
#
#   And, finally, substituting `k` from earlier:
#
# tree_sec = x_sec + ((inverse(width) * (y_sec - x_sec) (mod height))) * width
#
# The inverse of the width (or `pow(-1, height)`) is 51, and it could be just
# hardcoded, but openssl can solve it since apparently this kind of arithmetic
# is common in cryptography.
#
# Anyway, TIL:
# https://www.reddit.com/r/adventofcode/comments/1hdvhvu/comment/m1zws1g/

tree_sec = nil
begin
  require 'openssl' # For `mod_inverse`

  inverse_width_mod_height = OpenSSL::BN.new(bathroom.width).mod_inverse(bathroom.height).to_i
  x_sec, y_sec = x_max[:second], y_max[:second]
  width, height = bathroom.width, bathroom.height
  tree_sec = x_sec + ((inverse_width_mod_height * (y_sec - x_sec)) % height) * width
rescue Exception => e
  puts e
end

if tree_sec && tree_sec > 0
  puts tree_sec
  exit 0 unless use_the_brute_force
end

# Brute force solution:

x_sec, y_sec = x_max[:second], y_max[:second]
until x_sec == y_sec
  if x_sec < y_sec
    x_sec += bathroom.width
  else
    y_sec += bathroom.height
  end
end

puts x_sec

# My original solution below:
#
# I have no idea what the Christmas tree looks like, but it seems to be the
# single frame with the largest sum of robots on the same column (the trunk
# of the tree, I assume), and robots on the same row (the base of the tree?).
# I'm actually quite happy that I managed to find it without ever rendering
# the actual frame to check. And sad that I didn't get to see the tree.
#
# (In retrospect, looking at visualizations done by others, it seems that the
# tree has a border around it. So the reason why this worked so well is
# probably the border rather than the tree itself. But it worked!)

maybe_tree = { xy_max: x_max[:value], second: x_max[:second] }
robots.each { |robot| robot.move(map: bathroom, seconds: -seconds_to_run) }

require_relative '../ui'

rendering = Rendering.new(map: bathroom, robots: robots)

ui = make_ui(enabled: false)
ui.frame { |output| output << rendering }

second = 0
seconds_to_run = bathroom.width * bathroom.height
while second <= seconds_to_run
  ui.frame do |output|
    output << rendering

    x_count = {}
    x_count.default = 0
    y_count = x_count.dup
    robots.each do |robot|
      x_count[robot.position.x] += 1
      y_count[robot.position.y] += 1
    end
    xy_max = x_count.values.max + y_count.values.max
    if xy_max > maybe_tree[:xy_max]
      maybe_tree[:xy_max] = xy_max
      maybe_tree[:second] = second
      if xy_max == x_max[:value] + y_max[:value] # Later addition
        ui.close
        puts rendering
        puts second
        seconds_to_run = second
      end
    end

    robots.each { |robot| robot.move(map: bathroom) }
    second += 1
  end
end

puts maybe_tree[:second]
