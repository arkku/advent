#!/usr/bin/env ruby
# frozen_string_literal: true

inputs = $stdin.each_line.map(&:split).to_a

operators = inputs.pop
inputs = inputs.transpose

# @param operator [String]
# @param input [Array<Integer>]
# @return Integer
def calculate(operator, input)
  case operator
  when '*'
    input.inject(1) { |result, value| result * value }
  when '+'
    input.sum
  else
    raise "Unknown operator #{operator}"
  end
end

sum = 0
operators.each_with_index do |operator, index|
  input = inputs[index]
  sum += calculate(operator, input.map(&:to_i))
end

puts sum
