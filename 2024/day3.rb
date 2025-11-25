#!/usr/bin/env ruby
# frozen_string_literal: true

regex = /(do|don't|mul)\((\d{1,3},\d{1,3})?\)/

sum = 0
sum2 = 0

is_enabled = true

$stdin.each_line do |line|
  line.scan(regex) do |op, operands|
    if operands.to_s == ''
      if op == "do"
        is_enabled = true
      elsif op == "don't"
        is_enabled = false
      end
    elsif op == "mul"
      a, b = operands.to_s.split(',').map(&:to_i)
      result = a * b
      sum += result
      sum2 += result if is_enabled
    end
  end
end

puts sum
puts sum2
