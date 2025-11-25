#!/usr/bin/env ruby
# frozen_string_literal: true

columns = []
keys = []
locks = []

$stdin.each_line do |line|
  line.strip!
  if line.empty?
    (columns[0][0] == '#' ? locks : keys) << columns unless columns.empty?
    columns = []
    next
  end

  line.split('').each_with_index do |char, index|
    columns[index] = columns[index].to_s + char
  end
end
(columns[0][0] == '#' ? locks : keys) << columns unless columns.empty?

[locks, keys].each do |category|
  category.each do |entry|
    entry.map! { |col| col.count(col[0]) }
  end
end

fitting_pairs = 0
locks.each do |lock|
  keys.each do |key|
    if key.zip(lock).all? { |k, l| k >= l }
      fitting_pairs += 1
    end
  end
end

puts fitting_pairs
