#!/usr/bin/env ruby
# frozen_string_literal: true

inputs = $stdin.each_line.map(&:chars).to_a

operators = inputs.pop

# @param operator [String]
# @param input [[Integer]]
# @return Integer
def calculate(operator, input)
  case operator
  when '*'
    input.inject(1) { |result, value| result * value }
  when '+'
    input.sum
  else
    raise "Unknown operand #{operand}"
  end
end

sum = 0
previous_operator = nil

operators.each_with_index do |char, index|
  next unless ['*', '+', "\n"].include?(char)
  if previous_operator
    is_eol = char == "\n"

    operator = operators[previous_operator]
    input = previous_operator.upto(index - 1 - (is_eol ? 0 : 1)).map do |column|
      inputs.inject('') { |digits, row| digits + row[column].to_s }
    end
    input = input.map(&:strip).reject(&:empty?).map(&:to_i)

    result = calculate(operator, input)
    sum += result
    #puts "#{input.reverse.join(" #{operator} ")} = #{result}"
  end
  previous_operator = index
end

puts sum
