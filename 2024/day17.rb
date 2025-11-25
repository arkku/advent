#!/usr/bin/env ruby
# frozen_string_literal: true

class Machine
  attr_accessor :a, :b, :c, :pc, :output, :debug, :show_octal

  # @param registers [Array<Integer>]
  # @param program [Array<Integer>]
  # @param debug [Boolean]
  def initialize(registers:, program:, debug: false)
    @a, @b, @c = *registers
    @pc = 0
    @output = []
    @program = program.dup
    @halted = true
    @debug = debug
    @show_octal = false
  end

  # @return [Boolean]
  def halted?
    @halted
  end

  # @return [self]
  def run
    @halted = false
    until @halted
      opcode = @program[@pc]
      operand = @program[@pc + 1]
      unless opcode && operand && perform(opcode, operand)
        @halted = true
      end
    end
    self
  end

  # @param literal [Integer]
  # @return [Integer, nil]
  def combo(literal)
    case literal
    when 0, 1, 2, 3
      literal
    when 4
      @a
    when 5
      @b
    when 6
      @c
    end
  end

  # @param literal [Integer]
  # @return [String]
  def disasm_combo(literal)
    case literal
    when 0, 1, 2, 3
      show(literal)
    when 4
      "(A: #{show(@a)})"
    when 5
      "(B: #{show(@b)})"
    when 6
      "(C: #{show(@c)})"
    end
  end

  # @param opcode [Integer]
  # @param literal [Integer]
  # @return [String]
  def disasm(opcode, literal)
    case opcode
    when 0 # adv
      "adv A = (A: #{@a}) / 2**#{disasm_combo(literal)} = #{show(@a / 2**combo(literal))}"
    when 1 # bxl
      "bxl B = (B: #{show(@b)}) ^ #{show(literal)} = #{show(@b ^ literal)}"
    when 2 # bst
      "bst B = #{disasm_combo(literal)} & 7 = #{show(combo(literal).to_i & 7)}"
    when 3 # jnz
      if @a == 0
        "jnz A = (A: #{show(@a)}) == 0 -> NOP"
      else
        "jnz A = (A: #{show(@a)}) != 0 -> PC = #{literal}"
      end
    when 4 # bxc
      "bxc B = (B: #{show(@b)}) ^ (C: #{show(@c)}) = #{show(@b ^ @c)}"
    when 5 # out
      "out #{disasm_combo(literal)} & 7 = #{show(combo(literal).to_i & 7)}"
    when 6 # bdv
      "bdv B = (A: #{@a}) / 2**#{disasm_combo(literal)} = #{show(@a / 2**combo(literal))}"
    when 7 # cdv
      "cdv C = (A: #{@a}) / 2**#{disasm_combo(literal)} = #{show(@a / 2**combo(literal))}"
    end
  end

  # @param opcode [Integer]
  # @param literal [Integer]
  # @return [Integer, nil]
  def perform(opcode, literal)
    puts "#{@pc}\t#{opcode} #{literal} | #{disasm(opcode, literal)}" if debug

    case opcode
    when 0 # adv
      return nil unless (power = combo(literal))
      @a = (@a / (2**power)).to_i
    when 1 # bxl
      @b ^= literal
    when 2 # bst
      return nil unless (value = combo(literal))
      @b = value & 7
    when 3 # jnz
      if @a != 0
        @pc = literal
        return @pc
      end
    when 4 # bxc
      @b ^= @c
    when 5 # out
      return nil unless (value = combo(literal))
      @output << (value & 7)
    when 6 # bdv
      return nil unless (power = combo(literal))
      @b = (@a / (2**power)).to_i
    when 7 # cdv
      return nil unless (power = combo(literal))
      @c = (@a / (2**power)).to_i
    end
    @pc += 2
  end

  # @return [String]
  def result
    @output.join(',')
  end

  # @return [String]
  def b8(num)
    "[o#{num.to_i.to_s(8)}]"
  end

  # @return [String]
  def show(num)
    if !@show_octal || num.to_i < 8
      num.to_s
    else
      "#{num} #{b8(num)}"
    end
  end

  def to_s
    "\nA: #{show(@a)}\tB: #{show(@b)}\tC: #{show(@c)}\nPROGRAM: #{@program.join}\nPC:      #{' ' * @pc}^ #{@pc} #{@halted ? 'HALT' : ''}\nOUTPUT: #{@output.join}\n"
  end
end

# @param output [Array<Integer>]
# @param program [Array<Integer>]
# @param registers [Array<Integer>]
def find_a_for(output:, program:, registers:)
  candidates = [0]
  registers = registers.dup

  (1..output.length).each do |length|
    target = output[-length..]
    next_candidates = []

    candidates.each do |candidate|
      candidate <<= 3
      (0..7).each do |digit|
        registers[0] = candidate | digit
        machine = Machine.new(registers: registers, program: program, debug: false)
        machine.run
        next_candidates << registers[0] if machine.output == target
      end
    end
    candidates = next_candidates
  end

  candidates.min
end

registers = []
program = []

$stdin.each_line do |line|
  line.strip!
  next if line.empty?
  fields = line.split

  case fields.first
  when 'Register'
    registers << fields.last.to_i
  when 'Program:'
    fields.shift
    program = fields.last.to_s.split(',').map(&:to_i)
  end
end

machine = Machine.new(registers: registers, program: program, debug: true)
puts machine
machine.run
puts machine
part1 = machine.result

puts part1
puts find_a_for(output: program, program: program, registers: registers)
