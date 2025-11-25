#!/usr/bin/env ruby
# frozen_string_literal: true

class Gate
  attr_reader :input1, :type, :input2, :output

  SYMBOL_FOR_TYPE = { 'AND' => :&, 'OR' => :|, 'XOR' => :^ }.freeze

  # @param input1 [Wire]
  # @param type [String]
  # @param input2 [Wire]
  # @param output [Wire]
  def initialize(input1:, type:, input2:, output:)
    @input1 = input1
    @type = type
    @input2 = input2
    @output = output
    @distance = {}
  end

  # @param str [String]
  # @return [Gate, nil]
  def self.from_string(str)
    input1, type, input2, output = str.strip.split(/[ >-]+/)
    return nil unless input1 && type && input2 && output
    gate = Gate.new(
      input1: Wire.named(input1),
      type: type,
      input2: Wire.named(input2),
      output: Wire.named(output)
    )
    gate.wires.each { |wire| wire.add_gate(gate) }
    gate
  end

  # @return [Array<Wire>]
  def inputs
    [@input1, @input2]
  end

  # @return [Array<Wire>]
  def wires
    [@input1, @input2, @output]
  end

  # @return [Boolean]
  def input?
    @input1.input? || @input2.input?
  end

  # @return [Boolean]
  def output?
    @output.output?
  end

  # @param x [Integer]
  # @param y [Integer]
  # @return [Integer, nil]
  def resolve(x:, y:)
    @output.resolve(x: x, y: y)
  end

  # @param lhs [Integer]
  # @param rhs [Integer]
  # @return [Integer]
  def value(lhs, rhs)
    case type
    when 'AND'
      lhs & rhs
    when 'OR'
      lhs | rhs
    when 'XOR'
      lhs ^ rhs
    end
  end

  # @return [Boolean]
  def xor?
    type == 'XOR'
  end

  # @return [Boolean]
  def or?
    type == 'OR'
  end

  # @return [Boolean]
  def and?
    type == 'AND'
  end

  # @param wire [Wire, String]
  # @param distance [Integer]
  def set_distance(wire:, distance:)
    @distance[wire.respond_to?(:name) ? wire.name : wire.to_s] = distance
  end

  # @param wire [Wire, String]
  # @return [Integer, nil]
  def distance(wire:)
    @distance[wire.respond_to?(:name) ? wire.name : wire.to_s]
  end

  # @return [Symbol]
  def symbol
    SYMBOL_FOR_TYPE[type]
  end

  # @return [Array]
  def output_expression
    "#{@input1.expression}#{symbol}#{@input2.expression}"
  end

  def hash
    [@input1, @type, @input2, @output].hash
  end

  def ==(other)
    other.is_a?(Gate) && @output == other.output && @input1 == other.input1 && @input2 == other.input2 && @type == other.type
  end

  def eql?(other)
    self == other
  end

  def <=>(other)
    if @output != other.output
      @output <=> other.output
    else
      inputs <=> other.inputs
    end
  end

  def to_s
    "#{@input1} #{@type} #{@input2} -> #{@output}"
  end
end

class Wire
  attr_reader :name, :gates, :formula

  @by_name = Hash.new { |hash, name| hash[name] = Wire.new(name) }
  @by_formula = {}

  # @param name [String]
  def initialize(name)
    @name = name
    @gates = []
    @inputs = []
    @outputs = []
    @formula = nil
  end

  # @param name [String]
  # @return [Wire]
  def self.named(name)
    @by_name[name]
  end

  # @param prefix [String]
  # @param bit [Integer]
  # @return [Wire]
  def self.bit(prefix:, bit:)
    @by_name["#{prefix}#{format('%02d', bit)}"]
  end

  # @param bit [Integer]
  # @return [Wire]
  def self.x(bit)
    bit(prefix: 'x', bit: bit)
  end

  # @param bit [Integer]
  # @return [Wire]
  def self.y(bit)
    bit(prefix: 'y', bit: bit)
  end

  # @param bit [Integer]
  # @return [Wire]
  def self.z(bit)
    bit(prefix: 'z', bit: bit)
  end

  # @return [Array<Wire>]
  def self.xz(bit)
    [x(bit), z(bit)]
  end

  # @param name [String]
  # @return [Wire, nil]
  def self.with_formula(name)
    @by_formula[name]
  end

  def self.record_formula(wire)
    @by_formula[wire.formula] = wire
  end

  def self.delete_formula(old_formula)
    @by_formula.delete(old_formula)
  end

  # @param gate [Gate]
  def add_gate(gate)
    @gates << gate
    if gate.output == self
      raise "Multiple inputs for #{self}" if @gates.filter { |g| g.output == self }.count > 1
    elsif !gate.inputs.include?(self)
      raise "#{self} not in #{gate}"
    end
  end

  # @param x [Integer]
  # @param y [Integer]
  # @return [Integer, nil]
  def value(x:, y:)
    case name
    when /^x/
      (x >> index) & 1
    when /^y/
      (y >> index) & 1
    else
      if (gate = input_gate)
        input1 = gate.input1.value(x: x, y: y)
        input2 = gate.input2.value(x: x, y: y)
        return nil unless input1 && input2
        gate.value(input1, input2)
      end
    end
  end

  # @return [Gate, nil]
  def input_gate
    @gates.find { |gate| gate.output == self }
  end

  # @return [Array<Gate>]
  def output_gates
    @gates.filter { |gate| gate.output != self }
  end

  # @return [Array<Wire>]
  def outputs
    output_gates.map(&:output)
  end

  # @return [Array<Wire>]
  def inputs
    input_gate&.inputs
  end

  def each_gate_and_distance_downstream
    return enum_for(:each_gate_and_distance_downstream) unless block_given?

    steps = 0
    frontier = Set.new(output_gates)
    seen = Set.new
    until frontier.empty?
      seen.merge(frontier)
      next_frontier = Set.new
      frontier.each do |gate|
        yield [gate, steps]
        if (downstream = gate.output&.output_gates)
          next_frontier += downstream
        end
      end
      frontier = next_frontier - seen
      steps += 1
    end
    self
  end

  def each_gate_and_distance_upstream
    return enum_for(:each_gate_and_distance_upstream) unless block_given?

    steps = 0
    frontier = Set.new([input_gate])
    until frontier.empty?
      next_frontier = Set.new
      frontier.each do |gate|
        next unless gate
        yield [gate, steps]
        gate.inputs.each do |node|
          if (upstream = node.input_gate)
            next_frontier << upstream
          end
        end
      end
      frontier = next_frontier
      steps += 1
    end
    self
  end

  # @param type [String]
  # @return [Gate, nil]
  def output(type:)
    @gates.find { |gate| gate.type == type && gate.output != self }
  end

  # @return [Gate, nil]
  def xor_out
    output(type: 'XOR')
  end

  # @return [Gate, nil]
  def or_out
    output(type: 'OR')
  end

  # @return [Gate, nil]
  def and_out
    output(type: 'AND')
  end

  # @return [Boolean]
  def input?
    @name =~ /^[xy]/
  end

  # @return [Boolean]
  def output?
    @name.start_with?('z')
  end

  # @return [Integer, nil]
  def index
    @name[1..].to_i if @name =~ /^[xyz][0-9]/
  end

  def hash
    @name.hash
  end

  def <=>(other)
    @name <=> other.name
  end

  def ==(other)
    other.is_a?(Wire) && name == other.name
  end

  def eql?(other)
    self == other
  end

  # @param new_formula [String]
  def formula=(new_formula)
    Wire.delete_formula(@formula) if @formula
    @formula = new_formula
    Wire.record_formula(self)
  end

  # @return [String]
  def expression
    if @formula
      "(#{@formula})"
    else
      @name
    end
  end

  def to_s
    @name
  end
end

x = 0
y = 0

$stdin.each_line do |line|
  line.strip!
  break if line.empty?
  wire, value = line.split(': ')
  next if value == '0'
  bit = wire[1..].to_i
  case wire
  when /^x/
    x |= (value.to_i << bit)
  when /^y/
    y |= (value.to_i << bit)
  else
    exit 1
  end
end

gates = []
wires = Set.new

$stdin.each_line do |line|
  line.strip!
  break if line.empty?
  gate = Gate.from_string(line)
  exit 1 unless gate
  gates << gate
  wires += gate.wires
end

# @param z_wires [Array<Wire>]
# @param x [Integer]
# @param y [Integer]
# @return [Integer]
def wires_to_i(z_wires:, x:, y:)
  z = 0
  z_wires.sort.reverse.each do |wire|
    value = wire.value(x: x, y: y)
    z <<= 1
    z |= value & 1
  end
  z
end

z_wires = wires.filter(&:output?).sort
input_wires = wires.filter(&:input?).sort
x_wires = input_wires.filter { |wire| wire.name =~ /^x/ }
y_wires = input_wires.filter { |wire| wire.name =~ /^y/ }

z = wires_to_i(z_wires: z_wires, x: x, y: y)

num_bits = [x_wires.count, y_wires.count].max

puts z
exit 0 if num_bits <= 16

def mark_formulas_bfs(wires:)
  visited = Set.new
  queue = wires.uniq

  until queue.empty?
    wire = queue.shift

    next if visited.include?(wire)
    visited << wire

    wire.output_gates.each do |gate|
      gate.output.formula ||= gate.output_expression
      queue << gate.output
    end
  end
end

mark_formulas_bfs(wires: x_wires)

z_wires.each do |wire|
  wire.each_gate_and_distance_upstream do |gate, steps|
    #puts "#{wire}#{' ' * steps} #{gate}"
    gate.set_distance(wire: wire, distance: steps)
  end
end

x_wires.each do |wire|
  wire.each_gate_and_distance_downstream do |gate, steps|
    #puts "#{wire}#{' ' * steps} #{gate}"
    gate.set_distance(wire: wire, distance: steps)
  end
end

[0, 1, 2, 3, 4].each do |bit|
  wire = Wire.z(bit)
  upstream = wire.each_gate_and_distance_upstream.to_a
  max_steps = upstream.last.last
  upstream.reverse.each do |gate, steps|
    depth = max_steps - steps
    puts "#{format('%2d', steps)}#{'  ' * depth} #{gate}"
    puts "  #{'  ' * depth} #{gate.output_expression}"
  end
  puts
end

broken = Set.new

z_wires[...-1].each do |wire|
  # All outputs except the final carry bit must come from a XOR
  broken << wire unless wire.input_gate.xor?
end

# The last carry bit output must come from an OR gate
zlast = z_wires.last
broken << zlast unless zlast.input_gate.or?

gates.filter(&:xor?).each do |gate|
  wire = gate.output
  next if wire.output? # The outputs were already checked above

  if gate.input1.input?
    # XOR gates from x/y inputs must output to exactly one AND and one XOR gate
    broken << wire unless wire.and_out && wire.xor_out && wire.output_gates.count == 2
  else
    # All XOR gates must either be from x/y inputs and/or to z outputs
    broken << wire
  end
end

x00 = Wire.x(0)
z01 = Wire.z(1)
gates.filter(&:and?).each do |gate|
  wire = gate.output
  if gate.inputs.include?(x00)
    # The x00 AND y00 must output to a XOR gate for z01 and to an AND gate
    broken << wire unless wire.xor_out&.output == z01 && wire.and_out
  else
    # All other AND gates must output only to a single OR gate
    broken << wire unless wire.or_out && wire.output_gates.count == 1
  end
end

gates.filter(&:or?).each do |gate|
  wire = gate.output
  next if wire == zlast
  # All OR gates (except for the last carry bit) must output to exactly
  # one AND gate and one XOR gate
  broken << wire unless wire.and_out && wire.xor_out && wire.output_gates.count == 2
end

puts z
puts broken.to_a.sort.map(&:name).join(',')
