#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../ui'

SYMBOLS = (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a).freeze

Block = Struct.new(:num, :size) do # rubocop:disable Style/StructNewOverride
  # @return [Block]
  def self.make_free(size:)
    Block.new(num: -1, size: size)
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

  # @return [String]
  def to_s
    if num >= 0
      SYMBOLS[num % SYMBOLS.count] * size
    else
      '.' * size
    end
  end
end

file_count = 0
disk = []
$stdin.gets.chars.each_slice(2) do |entry|
  used, free = *entry.map(&:to_i)

  if used > 0
    disk << Block.new(num: file_count, size: used)
    file_count += 1
  end
  disk << Block.make_free(size: free) unless free == 0
end

ui = make_ui(enabled: disk.count < 20 || ARGV.include?('-v'))

tail_index = disk.count
first_free_index = disk.index(&:free?)

file_num = file_count - 1
while file_num >= 0
  break unless (file_index = disk[0...tail_index].rindex { |b| b.num == file_num })

  ui.frame do |output|
    output << disk

    file_num -= 1

    tail_index = file_index
    file = disk[file_index]

    next unless (free_block_index = disk[first_free_index...file_index].index { |b| b.free? && b.size >= file.size })
    free_block_index += first_free_index
    free_block = disk[free_block_index]

    disk[file_index] = Block.make_free(size: file.size) # Free the file's old block

    if free_block.size == file.size
      disk[free_block_index] = file
    else
      free_block.size -= file.size
      disk.insert(free_block_index, file)
      tail_index += 1
    end

    if free_block_index == first_free_index
      # The first free block has moved
      first_free_index = disk[free_block_index...].index(&:free?)
      first_free_index += free_block_index
    end
  end
end

ui.frame { |output| output << disk }
ui.close

checksum = 0
index = 0
disk.each do |block|
  next_index = index + block.size

  if block.file?
    (index...next_index).each do |position|
      checksum += position * block.num
    end
  end

  index = next_index
end

puts checksum
