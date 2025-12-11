import Foundation

typealias Bits = UInt8

final class Node {
    let id: String
    var outputs: [Node] = []

    init(id: String) {
        self.id = id
    }

    func distinctPathCount(to target: Node, passingThrough waypoints: Set<String> = []) -> Int {
        guard waypoints.count <= Bits.bitWidth else {
            fatalError("Too many waypoints")
        }

        var bitForWaypoint = [String: Bits]()
        for (index, id) in waypoints.enumerated() {
            bitForWaypoint[id] = Bits(1) << Bits(index)
        }

        // The cache is from node id, and then from remaining waypoints mask
        // to path count.
        var cache = [String: [Bits: Int]]()

        func dfs(_ node: Node, remainingWaypointsMask: Bits) -> Int {
            var cacheForNode = cache[node.id] ?? [:]
            if let cached = cacheForNode[remainingWaypointsMask] {
                return cached
            }

            var nextRemainingWaypointsMask = remainingWaypointsMask
            if let bit = bitForWaypoint[node.id] {
                nextRemainingWaypointsMask &= ~bit
            }

            let result: Int
            if node == target {
                result = if nextRemainingWaypointsMask == 0 {
                    1 // All waypoints visited
                } else {
                    0 // Path to target, but doesn't visit all waypoints
                }
            } else if node.outputs.isEmpty {
                result = 0
            } else {
                var total = 0
                for next in node.outputs {
                    total += dfs(next, remainingWaypointsMask: nextRemainingWaypointsMask)
                }
                result = total
            }

            cacheForNode[remainingWaypointsMask] = result
            cache[node.id] = cacheForNode
            return result
        }

        return dfs(self, remainingWaypointsMask: Bits((1 << waypoints.count) - 1))
    }
}

extension Node: Equatable {
    static func ==(lhs: Node, rhs: Node) -> Bool { lhs === rhs }
}

extension Node: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

final class Graph {
    private var nodeByID = [String: Node]()

    subscript(_ id: String) -> Node? {
        nodeByID[id]
    }

    func addEdges(from id: String, to outputs: [String]) {
        let node = makeOrFetchNode(id: id)
        let outputNodes = outputs.map { makeOrFetchNode(id: $0) }
        node.outputs.append(contentsOf: outputNodes)
    }

    func distinctPathCount(from start: String, to end: String, passingThrough waypoints: Set<String> = []) -> Int {
        guard let startNode = self[start], let endNode = self[end] else { return 0 }
        return startNode.distinctPathCount(to: endNode, passingThrough: waypoints)
    }

    private func makeOrFetchNode(id: String) -> Node {
        if let existing = nodeByID[id] {
            return existing
        }
        let node = Node(id: id)
        nodeByID[id] = node
        return node
    }
}

let graph = Graph()

while let line = readLine() {
    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedLine.isEmpty {
        continue
    }

    let fields = trimmedLine.split(separator: ":", maxSplits: 1)
    guard fields.count == 2 else { continue }

    let inputNode = String(fields[0])
    let outputNodes = fields[1]
        .trimmingCharacters(in: .whitespaces)
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)

    graph.addEdges(from: inputNode, to: outputNodes)
}

let pathCount = graph.distinctPathCount(from: "you", to: "out")
print(pathCount)

let serverPathCount = graph.distinctPathCount(
    from: "svr",
    to: "out",
    passingThrough: ["dac", "fft"]
)
print(serverPathCount)
