#!/usr/bin/env ruby
# frozen_string_literal: true

# @param operator [Symbol]
# @param lhs [Integer]
# @param rhs [Integer]
# @return [Integer]
def apply(operator, lhs, rhs)
  case operator
  when :+
    lhs + rhs
  when :*
    lhs * rhs
  when :|
    (10**(Math.log10(rhs).to_i + 1)) * lhs + rhs
  end
end

# @param result [Integer]
# @param operands [Array<Integer>]
# @param expected_result [Integer]
# @param operators [Array<Symbol>]
# @return [Boolean]
def test_permutations(result:, operands:, expected_result:, operators:)
  return false if result > expected_result # All operators increase the value

  if (operand = operands.first)
    suffix = operands[1..]
    operators.any? do |operator|
      test_permutations(
        result: apply(operator, result, operand),
        operands: suffix,
        expected_result: expected_result,
        operators: operators
      )
    end
  else
    result == expected_result
  end
end

sum = 0
sum2 = 0

$stdin.each_line do |line|
  expected_result, operands = line.split(': ')
  expected_result = expected_result.to_i
  result, *operands = operands.split.map(&:to_i)

  if test_permutations(result: result, operands: operands, expected_result: expected_result, operators: %i[* +])
    sum += expected_result
  elsif test_permutations(result: result, operands: operands, expected_result: expected_result, operators: %i[* + |])
    sum2 += expected_result
  end
end

puts sum
puts sum + sum2
