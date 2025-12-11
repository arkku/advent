#!/usr/bin/env ruby
# frozen_string_literal: true

def simulate(time:, robots:, resources:, costs:, cache: {}, best: 0)
  key = [time, robots, resources]
  if (cached = cache[key])
    return cached
  end

  return resources[0] if time == 0

  max_possible_geodes = resources[0] + robots[0] * time + (time * (time - 1)) / 2
  return 0 if max_possible_geodes <= best

  collected_resources = resources.dup
  robots.each_with_index { |count, type| collected_resources[type] += count }

  max_geodes = simulate(
    time: time - 1,
    robots: robots,
    resources: collected_resources,
    costs: costs,
    cache: cache,
    best: best
  )

  costs.each_with_index do |cost, robot_type|
    if cost.each_with_index.all? { |amount, resource| resources[resource] >= amount }
      new_resources = collected_resources.dup
      cost.each_with_index { |amount, resource| new_resources[resource] -= amount }

      new_robots = robots.dup
      new_robots[robot_type] += 1

      max_geodes = [
        max_geodes,
        simulate(
          time: time - 1,
          robots: new_robots,
          resources: new_resources,
          costs: costs,
          cache: cache,
          best: best
        )
      ].max
    end
  end

  cache[key] = max_geodes
end

blueprints = []
begin
  current_blueprint = []
  $stdin.each_line do |line|
    line.strip!
    next if line.empty?

    fields = line.split(/[.:] /)
    next if fields.empty?

    if fields.first.start_with?('Blueprint')
      blueprints << current_blueprint unless current_blueprint.empty?
      current_blueprint = []
      fields.shift
    end

    current_blueprint += fields
  end
  blueprints << current_blueprint unless current_blueprint.empty?
rescue StandardError => e
  p e
  exit 1
end

resource_index = { geode: 0, ore: 1 }

blueprints.map! do |blueprint|
  costs = {}
  costs.default = {}
  blueprint.each do |recipe|
    recipe.match(/^Each (\w+) robot costs ([^.]+)/) do |match|
      robot_type = match[1].to_sym
      unless resource_index.key?(robot_type)
        resource_index[robot_type] = resource_index.count
      end
      robot_costs = match[2].split(' and ').map(&:split).to_h { |a, r| [r.to_sym, a.to_i] }
      robot_costs.default = 0
      costs[robot_type] = robot_costs
    end
  end
  costs
end

blueprints.map! do |blueprint|
  costs = Array.new(resource_index.count) { Array.new(resource_index.count, 0) }
  blueprint.each_pair do |robot_type, recipe|
    recipe.each_pair do |cost_type, cost_count|
      costs[resource_index[robot_type]][resource_index[cost_type]] = cost_count
    end
  end
  costs
end

time_limit = 24

# Calculate checksum
checksum = 0

blueprints.each_with_index do |costs, index|
  robots = Array.new(resource_index.count, 0)
  resources = Array.new(resource_index.count, 0)
  robots[resource_index[:ore]] = 1

  geodes = simulate(time: time_limit, robots: robots, resources: resources, costs: costs, best: 0, cache: {})
  puts "Blueprint #{index + 1}: #{geodes} geodes"
  checksum += (index + 1) * geodes
end

puts checksum
