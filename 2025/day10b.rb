#!/usr/bin/env ruby
# frozen_string_literal: true

# Tried many different approaches, but couldn't come up with a good DIY
# solution. So here's the lazy way out that everyone else is doing: Z3
# (edit: Well, the Swift version now has a DIY solution that runs in under
# an hour, 90% of which is spent on a specific input. Z3 is milliseconds.)

Machine = Struct.new(:buttons, :joltage_requirements, keyword_init: true) do
  def minimum_button_presses
    z3_input = make_z3_minimum_button_presses_problem

    output = IO.popen(['z3', '-in', '-smt2'], 'r+') do |io|
      io.write(z3_input)
      io.close_write
      io.read
    end

    parse_z3_output(output)
  end

  private

  def make_z3_minimum_button_presses_problem
    lines = []
    lines << "(set-logic QF_LIA)"

    # Declare the buttons as non-negative integers
    buttons.count.times do |b|
      lines << "(declare-const b#{b} Int)"
      lines << "(assert (>= b#{b} 0))"
    end

    # Joltage equations
    # (assert (= (+ b0 b1 …)) 123) -> the sum of buttons for this joltage = 123
    joltage_requirements.each_with_index do |joltage, joltage_index|
      buttons_for_joltage = []
      buttons.each_with_index do |indices, b|
        buttons_for_joltage << "b#{b}" if indices.include?(joltage_index)
      end

      sum_expression =
        case buttons_for_joltage.count
        when 0
          '0'
        when 1
          buttons_for_joltage.first
        else
          "(+ #{buttons_for_joltage.join(' ')})"
        end
      lines << "(assert (= #{sum_expression} #{joltage}))"
    end

    # This is the goal: minimal sum of button presses
    # (minimize (+ b0 b1 …))
    lines << "(minimize (+ #{buttons.count.times.map { |b| "b#{b}" }.join(' ')}))"

    lines << "(check-sat)"
    lines << "(get-model)"
    "#{lines.join("\n")}\n"
  end

  def parse_z3_output(output)
    raise "z3 failed:\n#{output}" unless output.lines.first.strip == 'sat'

    presses_by_button = {}
    output.scan(/\(define-fun\s+b(\d+)\s+\(\)\s+Int\s+(-?\d+)\)/) do |button, presses|
      presses_by_button[button.to_i] = presses.to_i
    end

    presses_by_button.values.sum
  end
end

machines = $stdin.each_line.map(&:strip).reject(&:empty?).map do |line|
  fields = line.split
  buttons = fields[1...-1].map { |field| field[1..-2].split(",").map!(&:to_i) }
  joltage_requirements = fields.last[1..-2].split(",").map!(&:to_i)

  Machine.new(buttons: buttons, joltage_requirements: joltage_requirements)
end

total_presses = machines.sum(&:minimum_button_presses)
puts total_presses
