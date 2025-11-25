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
    size == 0
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

next_id = 0
disk = []
$stdin.gets.chars.each_slice(2) do |entry|
  used, free = *entry.map(&:to_i)

  disk << Block.new(num: next_id, size: used) unless used == 0
  disk << Block.make_free(size: free) unless free == 0

  next_id += 1
end

puts disk.join if disk.count < 20

# @param disk [Array<Block>]
# @return [nil, [Block, Integer]]
def last_file_with_index(disk)
  if (i = disk.rindex(&:file?))
    [disk[i], i]
  end
end

ui = make_ui(enabled: disk.count < 20 || ARGV.include?('-v'))

ui.frame do |output|
  output << disk
end

total_moved = 0
i = 0

while (free_block = disk[i])
  ui.frame do |output|
    output << disk

    unless free_block.free?
      i += 1
      next
    end

    until free_block.empty?
      file, file_index = last_file_with_index(disk)
      if file.nil?
        i = disk.count
        break
      elsif file.empty?
        disk.delete_at(file_index)
        i -= 1 if file_index < i
        next
      end

      moved_blocks = [file.size, free_block.size].min
      next unless moved_blocks > 0

      total_moved += moved_blocks
      free_block.size -= moved_blocks
      file.size -= moved_blocks

      new_block = Block.new(file.num, moved_blocks)
      if file.empty?
        disk.delete_at(file_index)
        i -= 1 if file_index < i
      end

      if free_block.empty?
        disk[i] = new_block
      else
        disk.insert(i, new_block)
        i += 1
      end
    end
  end
end

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

disk.append(Block.make_free(size: total_moved)) if total_moved > 0

puts checksum
