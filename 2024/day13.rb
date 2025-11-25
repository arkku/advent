#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../coords'

# This finds the intersection of the lines defined by a and b. Basically it
# solves the equations, rearranged with the help of AI because I really
# can't be bothered with this kind of math:
#
# a_count * a.x + b_count * b.x = target.x
# a_count * a.y + b_count * b.y = target.y
#
# In theory it's possible that the lines would be the same line, but with
# different "speed": e.g., a = (200, 100), b = (50, 25), and if the prize
# is at (250, 125) the cost would be 4 .
#
# Somewhat annoyingly, the input seems to be crafted to avoid this special
# case, so those people who didn't think of this possibility and just tried
# the intersecting lines solution have had an easier time. Still, this supports
# those corner cases. There is a `corner13.txt` to test them.
#
# @param target [Coords]
# @param a [Coords]
# @param b [Coords]
# @param a_price [Integer]
# @param b_price [Integer]
# @return [Integer, nil]
def find_cost_alg(target:, a:, b:, a_price: 3, b_price: 1)
  return 0 if target.zero?

  if a.colinear?(b) || a.zero? || b.zero?
    # This never happens in the actual puzzle input
    costs = []

    [[b, a, b_price, a_price], [a, b, a_price, b_price]].each do |primary, secondary, primary_price, secondary_price|
      next if primary.zero?

      primary_count =
        if primary.x.zero?
          target.y.to_i / primary.y.to_i
        else
          target.x.to_i / primary.x.to_i
        end
      remaining = target - primary * primary_count
      if (secondary_count = secondary.factor_of?(remaining))
        costs << (primary_count * primary_price + secondary_count * secondary_price)
      end
    end

    return costs.min
  end

  denominator = a.x * b.y - b.x * a.y
  return nil if denominator.zero?

  a_count, remainder = (target.x * b.y - target.y * b.x).divmod(denominator)
  return nil unless remainder.zero? && a_count >= 0

  b_count, remainder =
    if b.x.zero?
      (target.y - a.y * a_count).divmod(b.y)
    else
      (target.x - a.x * a_count).divmod(b.x)
    end

  return nil unless remainder.zero? && b_count >= 0

  a_price * a_count + b_price * b_count
end

# This is the naive solution that just tries all possible b counts
# @param target [Coords]
# @param a [Coords]
# @param b [Coords]
# @param a_price [Integer]
# @param b_price [Integer]
# @return [Integer, nil]
def find_cost_brute(target:, a:, b:, a_price: 3, b_price: 1)
  best_cost = nil

  max_b_count = [(b.x.zero? ? 0 : target.x / b.x), (b.y.zero? ? 0 : target.y / b.y)].max
  (0..max_b_count).each do |b_count|
    total_cost = b_count * b_price
    break if best_cost && total_cost > best_cost

    remaining = target - b * b_count

    unless remaining.zero?
      ax_count = a.x.zero? ? 0 : remaining.x / a.x
      ay_count = a.y.zero? ? 0 : remaining.y / a.y
      a_count = [ax_count, ay_count].max

      remaining -= a * a_count
      total_cost += a_count * a_price
    end

    best_cost = total_cost if remaining.zero? && (best_cost.nil? || total_cost < best_cost)
  end

  best_cost
end

tokens = 0
tokens2 = 0

modifier = Coords.new(x: 10_000_000_000_000, y: 10_000_000_000_000).freeze

while (line = $stdin.gets&.strip)
  next if line.empty?
  _, _, ax, ay = line.split(/[XY,+ ]+/).map(&:to_i)
  break unless (line = $stdin.gets)
  _, _, bx, by = line.split(/[XY,+ \n]+/).map(&:to_i)
  break unless (line = $stdin.gets)
  _, px, py = line.split(/[XY,= \n]+/).map(&:to_i)

  a = Coords.new(ax, ay).freeze
  b = Coords.new(bx, by).freeze
  prize = Coords.new(px, py).freeze

  cost = find_cost_brute(target: prize, a: a, b: b).to_i

  tokens += cost
  tokens2 += find_cost_alg(target: prize + modifier, a: a, b: b).to_i
end

puts tokens
puts tokens2
