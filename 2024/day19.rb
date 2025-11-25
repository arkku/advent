#!/usr/bin/env ruby
# frozen_string_literal: true

# @param pattern [String]
# @param from [Array<String>]
# @return [Boolean]
def form_pattern(pattern, from:)
  return true if pattern.empty?

  len = pattern.length

  from.each do |part|
    part_len = part.length
    next if part_len > len

    prefix = pattern[0...part_len]
    if prefix == part
      return true if form_pattern(pattern[part_len..], from: from)
    elsif prefix < part
      break
    end
  end

  false
end

# @param pattern [String]
# @param from [Array<String>]
# @param cache [Hash<String, Integer>]
# @return [Integer]
def ways_to_form(pattern:, from:, cache: {})
  if (cached = cache[pattern])
    return cached
  end

  return (cache[pattern] = 1) if pattern.empty?

  ways = 0

  from.each do |part|
    part_len = part.length
    next if part_len > pattern.length

    if pattern.start_with?(part)
      ways += ways_to_form(pattern: pattern[part_len..], from: from, cache: cache)
    end
  end

  cache[pattern] = ways
  ways
end

towels = $stdin.gets.strip.split(/[, ]+/).sort

output_enabled = towels.count < 15 || ARGV.include?('-v')
puts "parts = #{towels.join(', ')}" if output_enabled

possible_count = 0
ways_count = 0

$stdin.each_line do |line|
  pattern = line.strip!
  next if pattern.empty?
  if form_pattern(pattern, from: towels)
    possible_count += 1
    permutations = ways_to_form(pattern: pattern, from: towels)
    ways_count += permutations
    puts "#{pattern} can be formed in #{permutations} ways" if output_enabled
  end
end

puts possible_count
puts ways_count
