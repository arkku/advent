#!/usr/bin/env ruby
# frozen_string_literal: true

ranges = $stdin.each_line.flat_map do |line|
  line.strip.split(',').map do |field|
    field.split('-').map(&:to_i)
  end
end

# Full disclosure: the actual math here is entirely done by AI, which got it
# right on the first try. I refused to do the brute force solution, but
# couldn't figure out the math myself. =(

# @param lower [Integer]
# @param upper [Integer]
# @yield [id]
# @yieldparam id [Integer]
def each_of_digits_repeated_twice_in(lower, upper)
  return enum_for(:each_of_digits_repeated_twice_in, lower, upper) unless block_given?

  digits = Math.log10(upper).ceil.to_i
  max_k = digits / 2
  (1..max_k).each do |k|
    factor = 10**k + 1
    pmin = (lower + factor - 1) / factor
    pmax = upper / factor

    lo = 10**(k - 1)
    hi = 10**k - 1

    pmin = [pmin, lo].max
    pmax = [pmax, hi].min
    next if pmin > pmax

    (pmin..pmax).each do |p|
      yield p * factor
    end
  end
end

# @param lower [Integer]
# @param upper [Integer]
# @yield [id]
# @yieldparam id [Integer]
def each_of_digits_repeated_at_least_three_times_in(lower, upper)
  return enum_for(:each_of_digits_repeated_at_least_three_times_in, lower, upper) unless block_given?

  digits = Math.log10(upper).ceil.to_i

  (1..digits).each do |k|
    max_t = digits / k
    next if max_t < 3

    (3..max_t).each do |t|
      pow_kt = 10**(k * t)
      pow_k  = 10**k
      factor = (pow_kt - 1) / (pow_k - 1)

      pmin = (lower + factor - 1) / factor
      pmax = upper / factor

      lo = 10**(k - 1)
      hi = pow_k - 1

      pmin = [pmin, lo].max
      pmax = [pmax, hi].min
      next if pmin > pmax

      (pmin..pmax).each do |p|
        yield p * factor
      end
    end
  end
end

sum_exactly_twice = 0
sum_at_least_three_times = 0
seen = Set.new

ranges.each do |lower, upper|
  each_of_digits_repeated_twice_in(lower, upper) do |match|
    next if seen.include?(match)
    seen << match
    sum_exactly_twice += match
  end
  each_of_digits_repeated_at_least_three_times_in(lower, upper) do |match|
    next if seen.include?(match)
    seen << match
    sum_at_least_three_times += match
  end
end

puts sum_exactly_twice
puts sum_exactly_twice + sum_at_least_three_times
