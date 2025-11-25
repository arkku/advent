#!/usr/bin/env crystal run

class Node
  @name : String
  getter name

  @neighbours : Set(Node)
  getter neighbours

  def initialize(name : String)
    @name = name
    @neighbours = Set(Node).new
  end

  def add_edge(to : Node)
    return nil if neighbours.includes?(to) || to === self
    @neighbours << to
  end

  def degree : Int32
    @neighbours.size
  end

  def neighbourhood : Array(Node)
    [self].concat(@neighbours)
  end

  def largest_cliques(of_at_least : Int32 = 0) : Array(Set(Node))
    result = [] of Set(Node)

    upper = degree + 1
    lower = of_at_least.clamp(2, upper + 1)

    while lower <= upper
      mid = (lower + upper) // 2
      cliques = cliques_of_size(mid)
      if cliques.empty?
        upper = mid - 1
      else
        result = cliques
        lower = mid + 1
      end
    end

    result
  end

  def cliques_of_size(size : Int32) : Array(Set(Node))
    cliques = [] of Set(Node)
    cliques << Set(Node).new([self]) if size == 1
    return cliques unless size > 1

    @neighbours.to_a.combinations(size - 1).each do |candidate|
      if candidate.combinations(2).all? { |(n1, n2)| n1.adjacent_or_self?(n2) }
        cliques << Set(Node).new([self] + candidate)
      end
    end

    cliques
  end

  def component : Set(Node)
    frontier = Set(Node).new([self])
    visited = Set(Node).new

    until frontier.empty?
      visited.concat(frontier)
      next_frontier = Set(Node).new
      frontier.each { |node| next_frontier.concat(node.neighbours) }
      next_frontier.subtract(visited)
      frontier = next_frontier
    end

    visited
  end

  def adjacent?(node : Node) : Bool
    @neighbours.includes?(node)
  end

  def adjacent_or_self?(node : Node) : Bool
    adjacent?(node) || node === self
  end

  def hash : UInt64
    @name.hash
  end

  def ==(other : Node) : Bool
    self.eql?(other)
  end

  def eql?(other : Node) : Bool
    other.is_a?(Node) && @name == other.name
  end

  def <=>(other)
    @name <=> other.name
  end

  def to_s(io : IO)
    io << @name
  end
end

class Graph
  @node_by_name : Hash(String, Node)

  def initialize(nodes : Set(Node) | Nil = nil)
    @node_by_name = Hash(String, Node).new
    if nodes
      nodes.each do |node|
        @node_by_name[node.name] = node
      end
    end
  end

  def add_edge(name1 : String, name2 : String)
    node1 = @node_by_name.put_if_absent(name1, Node.new(name: name1))
    node2 = @node_by_name.put_if_absent(name2, Node.new(name: name2))
    node1.add_edge(node2)
    node2.add_edge(node1)
  end

  def components : Array(Graph)
    result = [] of Graph
    seen = Set(Node).new
    @node_by_name.values.each do |node|
      next if seen.includes?(node)
      component = node.component
      result << Graph.new(component)
      seen.concat(component)
    end
    result
  end

  def largest_cliques : Array(Set(Node))
    largest = [] of Set(Node)
    largest_size = 0
    sorted_by_degree = nodes.sort { |a, b| b.degree <=> a.degree }
    sorted_by_degree.each do |node|
      break if node.degree < largest_size

      cliques = node.largest_cliques(of_at_least: largest_size)

      if (clique = cliques.first?)
        if clique.size > largest_size
          largest = cliques
          largest_size = clique.size
        elsif !largest.includes?(clique)
          largest.concat(cliques)
        end
      end
    end
    largest
  end

  def nodes : Array(Node)
    @node_by_name.values
  end

  def size : Int32
    @node_by_name.size
  end

  def each_node
    @node_by_name.each_value do |node|
      yield node
    end
  end

  def to_s(io : IO)
    io << "Graph(#{@node_by_name.values.join(", ")})"
  end
end

graph = Graph.new

STDIN.each_line do |line|
  name1, name2 = line.strip.split('-')
  next unless name1 && name2
  graph.add_edge(name1, name2)
end

triangles = Set(Set(Node)).new
graph.each_node do |node|
  next unless node.name.starts_with?('t')
  node.cliques_of_size(3).each do |clique|
    triangles << clique
  end
end

puts triangles.size

largest_cliques = graph.largest_cliques
puts largest_cliques.first.to_a.sort.join(",")
