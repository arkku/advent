#!/usr/bin/env ruby
# frozen_string_literal: true

POSITIONS = 100
STARTING_POSITION = 50

rotations = $stdin.each_line.map do |line|
  sign = (line.slice!(/[LR]/) == 'L' ? -1 : 1)
  sign * line.to_i
end.to_a

on_zero_count = 0
through_zero_count = 0
position = STARTING_POSITION

rotations.each do |rotation|
  # Step 2 special case: there may be complete revolutions that pass over 0
  # multiple times in the same action, let's count those separately
  complete_revolutions = rotation.abs / POSITIONS
  through_zero_count += complete_revolutions

  # Now, the last rotation is always < POSITIONS in length
  rotation = rotation.remainder(POSITIONS)
  old_position = position
  position += rotation

  if rotation >= 0
    through_zero_count += 1 if position >= POSITIONS
  elsif old_position != 0
    # ^- Don't count if the last rotation starts from zero
    through_zero_count += 1 if position <= 0
  end

  position %= POSITIONS

  on_zero_count += 1 if position == 0
end

puts on_zero_count
puts through_zero_count
