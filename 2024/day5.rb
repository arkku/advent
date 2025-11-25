#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../stablesort'

pages_before = {}

$stdin.each_line do |line|
  b, a = line.split('|')
  break if b.nil? || a.nil?

  (pages_before[a.to_i] ||= Set.new).add(b.to_i)
end

pages_before.default = []

checksum = 0
checksum2 = 0

$stdin.each_line do |line|
  pages = line.split(',')&.map(&:to_i).freeze
  next unless pages

  forbidden_pages = Set.new

  is_valid = true
  pages.each do |page|
    if forbidden_pages.include?(page)
      # This page should have come before an earlier page
      is_valid = false
      break
    else
      # These pages are not allowed in the suffix
      forbidden_pages.merge(pages_before[page])
    end
  end

  if is_valid
    checksum += pages[pages.count / 2].to_i
  else
    corrected_pages = pages.stablesort do |a, b|
      if pages_before[b]&.include?(a)
        -1
      elsif pages_before[a]&.include?(b)
        1
      else
        0
      end
    end
    checksum2 += corrected_pages[corrected_pages.count / 2]
  end
end

puts checksum
puts checksum2
