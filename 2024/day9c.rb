#!/usr/bin/env ruby
# frozen_string_literal: true

require 'algorithms'

SYMBOLS = (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a).freeze
FREE_NUM = -1

Block = Struct.new(:num, :index, :size, :next, :prev) do # rubocop:disable Style/StructNewOverride
  # @param index [Integer]
  # @return [Block]
  def self.make_sentinel(index:)
    Block.new(num: FREE_NUM, index: index, size: 0)
  end

  # @return [Integer]
  def <=>(other)
    index <=> other.index
  end

  # @return [Integer]
  def hash
    index.hash ^ num.hash ^ size.hash
  end

  # @return [Boolean]
  def free?
    num < 0
  end

  # @return [Boolean]
  def file?
    num >= 0
  end

  # @return [Boolean]
  def empty?
    count == 0
  end

  # @param node [Block]
  # @return [Block]
  def link(node)
    old_next = self.next
    self.next = node
    node.next = old_next
    node.prev = self
    node
  end

  # @return [self]
  def replace_with(node)
    node.prev = prev
    node.next = self.next
    prev.next = node
    self.next.prev = node
    self
  end

  # @yield [node]
  # @yieldparam node [Block]
  def each
    node = self
    until node.nil?
      yield node
      node = node.next
    end
  end

  # @yield [node]
  # @yieldparam node [Block]
  def each_reverse
    node = self
    until node.nil?
      yield node
      node = node.prev
    end
  end

  # @yield [node]
  # @yieldparam node [Block]
  # @yieldreturn [Boolean] Return `true` on match.
  # @return [Block, nil]
  def first
    node = self
    if block_given?
      until node.nil?
        result = yield node
        break if result
        node = node.next
      end
    end
    node
  end

  # @yield [node]
  # @yieldparam node [Block]
  # @yieldreturn [Boolean] Return `true` on match.
  # @return [Block, nil]
  def find_reverse
    node = self
    until node.nil?
      break if yield node
      node = node.prev
    end
    node
  end

  # @param separator [String]
  # @return [String]
  def join(separator = '')
    result = ''
    each do |block|
      result << separator unless result.empty?
      result << block.to_s
    end
    result
  end

  # @param file [IO]
  def print_all(file = $stdout)
    each do |block|
      file << block.to_s
    end
    file << "\n"
  end

  # @return [String]
  def inspect
    "(#{self} #{size}×#{num} i=#{index} next=#{self.next&.index} #{self.next} prev=#{prev&.index} #{prev})"
  end

  # @return [Array<Block>]
  def to_a
    result = []
    each { |block| result << block unless block.empty? }
    result
  end

  # @return [String]
  def to_s
    if file?
      SYMBOLS[num % SYMBOLS.count] * size
    else
      '.' * size
    end
  end
end

head = Block.make_sentinel(index: 0)
tail = head

file_count = 0
index = 0
max_size = 1

file_blocks = []
free_blocks = Hash.new { |hash, size| hash[size] = Containers::MinHeap.new }

$stdin.gets.chars.each_slice(2) do |entry|
  used, free = *entry.map(&:to_i)

  if used > 0
    block = Block.new(num: file_count, index: index, size: used)
    tail = tail.link(block)
    file_blocks << tail
    file_count += 1
    index += 1
  end
  if free > 0
    block = Block.new(num: FREE_NUM, index: index, size: free)
    tail = tail.link(block)
    free_blocks[free].push(block)
    index += 1
    max_size = free if free > max_size
  end
end

tail.link(Block.make_sentinel(index: index))

disk = head.next

file_blocks.reverse.each do |file|
  free_block, free_block_heap = nil, nil
  file.size.upto(max_size) do |size|
    heap = free_blocks[size]
    next unless (block = heap.next)
    if block && block.index < file.index && (free_block.nil? || free_block.index > block.index)
      free_block, free_block_heap = block, heap
    end
  end

  next unless free_block

  disk.print_all if file_blocks.count < 20

  free_block_heap.pop

  if free_block.size == file.size
    free_block.num = file.num
    free_block.index = file.index
  else
    moved_file = Block.new(num: file.num, index: file.index, size: file.size, prev: free_block.prev, next: free_block)
    moved_file.prev.next = moved_file
    free_block.prev = moved_file
    free_block.size -= file.size

    free_blocks[free_block.size].push(free_block)
  end

  file.num = FREE_NUM
end

checksum = 0
index = 0
head.each do |block|
  next_index = index + block.size

  if block.file?
    (index...next_index).each do |position|
      checksum += position * block.num
    end
  end

  index = next_index
end

disk.print_all if file_blocks.count < 20
puts checksum
