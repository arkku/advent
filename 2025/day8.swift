import Foundation

// MARK: -

struct Node: Hashable, Sendable {
    typealias Value = Int64

    let id: Int
    let x: Value
    let y: Value
    let z: Value

    init(id: Int, coordinates: [Value]) {
        self.id = id
        self.x = coordinates[0]
        self.y = coordinates[1]
        self.z = coordinates[2]
    }

    func squaredDistance(to other: Node) -> Value {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return dx * dx + dy * dy + dz * dz
    }
}

// MARK: - Algorithms

func edgesSortedByDistance(between nodes: [Node]) -> [(Int, Int)] {
    var result = [(distance: Int64, a: Int, b: Int)]()
    result.reserveCapacity(nodes.count * (nodes.count - 1) / 2)

    for a in nodes {
        for b in nodes.suffix(from: a.id + 1) {
            let distance = a.squaredDistance(to: b)
            result.append((distance: distance, a: a.id, b: b.id))
        }
    }

    result.sort { $0.distance < $1.distance }
    return result.map { ($0.a, $0.b) }
}

func connectedComponent(root: Int, neighbours: [Int: Set<Int>]) -> Set<Int> {
    var frontier: Set<Int> = [root]
    var visited = Set<Int>()

    while !frontier.isEmpty {
        visited.formUnion(frontier)
        var nextFrontier = Set<Int>()

        for node in frontier {
            if let neigh = neighbours[node] {
                nextFrontier.formUnion(neigh)
            }
        }

        nextFrontier.subtract(visited)
        frontier = nextFrontier
    }

    return visited
}

// MARK: - Input

var nodes: [Node] = []
while let line = readLine(strippingNewline: true) {
    let fields = line.split(separator: ",").compactMap { Node.Value($0) }
    if fields.count != 3 { fatalError("Invalid input: \(line)") }
    nodes.append(Node(id: nodes.count, coordinates: fields))
}

guard nodes.count > 0 else { fatalError("No input") }


// MARK: - Part 1

let linkCount = nodes.count < 30 ? 10 : 1000
let edges = edgesSortedByDistance(between: nodes)

let initialEdges = Array(edges.prefix(linkCount))
var neighbours: [Int: Set<Int>] = [:]
for (a, b) in initialEdges {
    neighbours[a, default: []].insert(b)
    neighbours[b, default: []].insert(a)
}

// Find all connected components

var remainingNodes = Set(nodes.map(\.id))
var components: [Set<Int>] = []

while let root = remainingNodes.first {
    let comp = connectedComponent(root: root, neighbours: neighbours)
    remainingNodes.subtract(comp)
    components.append(comp)
}

let sizes = components.map { $0.count }.sorted(by: >)
print(sizes.prefix(3).reduce(into: 1) { $0 *= $1 })

// MARK: - Part 2

var componentOfNode: [Int: Int] = [:]
var componentById: [Int: Set<Int>] = [:]

for (componentId, component) in components.enumerated() {
    componentById[componentId] = component
    for node in component {
        componentOfNode[node] = componentId
    }
}

let remainingEdges = edges.suffix(from: linkCount)

for (a, b) in remainingEdges {
    guard let componentA = componentOfNode[a], let componentB = componentOfNode[b] else {
        fatalError("No component for \(a) - \(b) edge")
    }
    if componentA == componentB { continue }

    // Two components got merged, move the smaller into the larger

    let nodesA = componentById[componentA]!
    let nodesB = componentById[componentB]!

    if (nodesA.count, componentA) < (nodesB.count, componentB) {
        for node in nodesA {
            componentOfNode[node] = componentB
        }
        componentById[componentB] = nodesB.union(nodesA)
        componentById.removeValue(forKey: componentA)
    } else {
        for node in nodesB {
            componentOfNode[node] = componentA
        }
        componentById[componentA] = nodesA.union(nodesB)
        componentById.removeValue(forKey: componentB)
    }

    if componentById.count == 1 {
        // The entire graph is now one component
        print(nodes[a].x * nodes[b].x)
        break
    }
}
