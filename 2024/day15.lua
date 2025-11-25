#!/usr/bin/env lua
Coords = {}
Coords.__index = Coords

function Coords.new(x, y)
    return setmetatable({ x = x, y = y }, Coords)
end

function Coords.from_char(c)
    if c == "^" then
        return Coords.new(0, -1)
    elseif c == "v" then
        return Coords.new(0, 1)
    elseif c == "<" then
        return Coords.new(-1, 0)
    elseif c == ">" then
        return Coords.new(1, 0)
    else
        return nil
    end
end

function Coords:add(o)
    return Coords.new(self.x + o.x, self.y + o.y)
end

function Coords:lanternfish_gps()
    -- Lua's coordinates are 1-based so need to adjust to 0-based
    return 100 * (self.y - 1) + (self.x - 1)
end

Map = {}
Map.__index = Map

function Map.new(rows)
  local map = { map = {} }
  for i, row in ipairs(rows) do
      map.map[i] = { table.unpack(row) }
  end
  return setmetatable(map, Map)
end

function Map:get(c)
  local row = self.map[c.y]
  return row and row[c.x] or nil
end

function Map:set(c, v)
  local row = self.map[c.y]
  if row then row[c.x] = v end
end

function Map:push(from, move, perform)
  local to = from:add(move)
  local c = self:get(to)
  if c == "O" then
    if not self:push(to, move, perform) then return false end
  elseif c == "[" or c == "]" then
    if move.y ~= 0 then
      local other_half = Coords.new(to.x + (c == "[" and 1 or -1), to.y)
      if not self:push(other_half, move, false) then return false end
      if not self:push(to, move, perform) then return false end
      if perform then self:push(other_half, move, true) end
    else
      if not self:push(to, move, perform) then return false end
    end
  elseif c == "#" then
    return false
  end
  if perform then
    self:set(to, self:get(from))
    self:set(from, ".")
  end
  return true
end

function Map:widened()
  local wide_rows = {}
  for _, row in ipairs(self.map) do
    local wide_row = {}
    for _, c in ipairs(row) do
      if c == "O" or c == "[" or c == "]" then
        wide_row[#wide_row + 1] = "["
        wide_row[#wide_row + 1] = "]"
      elseif c == "@" then
        wide_row[#wide_row + 1] = "@"
        wide_row[#wide_row + 1] = "."
      else
        wide_row[#wide_row + 1] = c
        wide_row[#wide_row + 1] = c
      end
    end
    wide_rows[#wide_rows + 1] = wide_row
  end
  return Map.new(wide_rows)
end

function Map:each_box(f)
  for y, row in ipairs(self.map) do
    for x, c in ipairs(row) do
      if c == "O" or c == "[" then
          f(Coords.new(x, y))
      end
    end
  end
end

function Map:to_string()
  local lines = {}
  for _, row in ipairs(self.map) do
      lines[#lines + 1] = table.concat(row)
  end
  return table.concat(lines, "\n")
end

local rows = {}
local robot

for line in io.lines() do
  local chars = {}
  local robot_x = nil

  for char in line:gmatch("%S") do
    if char == "@" then
      robot = Coords.new(#chars + 1, #rows + 1)
      char = "."
    end
    chars[#chars + 1] = char
  end

  if #chars == 0 then break end -- empty line

  rows[#rows + 1] = chars
end

local map = Map.new(rows)
local widened_map = map:widened()
local runs = { { map, robot }, { widened_map, Coords.new(robot.x * 2 - 1, robot.y) } }
local moves = {}

for line in io.lines() do
  for char in line:gmatch("%S") do
    local move = Coords.from_char(char)
    if move then
      moves[#moves + 1] = move
    end
  end
end

local output_enabled = (#moves < 100) or (arg[1] == "-v")

for _, run in ipairs(runs) do
  local map, robot = run[1], run[2]
  map:set(robot, "@")
  if output_enabled then print(map:to_string()) end

  for _, move in ipairs(moves) do
    if map:push(robot, move, true) then
      robot = robot:add(move)
      if output_enabled then print(map:to_string()) end
    end
  end

  local sum = 0
  map:each_box(function(box) sum = sum + box:lanternfish_gps() end)
  print(sum)
end
