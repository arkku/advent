# frozen_string_literal: true

class Array
  # @yield [a, b]
  # @yieldparam a [Object]
  # @yieldparam b [Object]
  # @yieldreturn [Integer]
  # @param comparator [Proc, nil]
  # @return [Array<Object>]
  def stablesort(&comparator)
    comparator ||= ->(a, b) { a <=> b }
    sorted = each_with_index.sort do |(a, ai), (b, bi)|
      result = comparator.call(a, b)
      result.zero? ? (ai <=> bi) : result
    end
    sorted.map { |a, _| a }
  end
end
