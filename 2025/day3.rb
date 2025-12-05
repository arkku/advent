#!/usr/bin/env ruby
# frozen_string_literal: true

banks = $stdin.each_line.map { |line| line.strip.split('').map(&:to_i) }

# @param digits [Integer] The number of digits (batteries) to take from `bank`.
# @param bank [Array<Integer>] The batteries (digits).
#   - Precondition: `bank.length >= digits`
# @param joltage [Integer] The accumulator (battery?) for recursion, optional.
# @return [Integer]
def max_joltage(digits:, bank:, joltage: 0)
  return joltage if digits.zero?

  # Pick the greatest digit that leaves enough remaining digits to fill up
  max_digit, i = bank[..-digits].each_with_index.max_by { |digit, _| digit }

  max_joltage(
    digits: digits - 1,
    bank: bank.drop(i + 1),
    joltage: joltage * 10 + max_digit
  )
end

[2, 12].each do |digits|
  sum = banks.sum do |bank|
    max_joltage(digits: digits, bank: bank)
  end
  puts sum
end
