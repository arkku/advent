import Foundation

final class Machine: Sendable {
    typealias Bits = UInt

    enum Failure: Error {
        case noButtons
        case invalidInput(String)
        case activationPatternTooLong(String)
    }

    private let activationPattern: Bits
    private let buttons: [(bitmask: Bits, indices: [Int])]
    private let joltageRequirements: [Int]

    init(activationPattern: String, buttons: [[Int]], joltageRequirements: [Int]) throws {
        guard activationPattern.count <= Bits.bitWidth else {
            throw Failure.activationPatternTooLong(activationPattern)
        }
        self.activationPattern = Machine.bitmask(fromPattern: activationPattern)

        var seenBitmasks = Set<Bits>()

        self.buttons = buttons.compactMap { buttonTargetIndices in
            guard !buttonTargetIndices.isEmpty else { return nil }
            let bitmask = Machine.bitmask(fromBitIndices: buttonTargetIndices)
            if seenBitmasks.insert(bitmask).inserted {
                return (bitmask: bitmask, indices: buttonTargetIndices)
            } else {
                return nil
            }
        }

        self.joltageRequirements = joltageRequirements

        guard !buttons.isEmpty else { throw Failure.noButtons }
    }

    private static func bitmask(fromPattern pattern: String) -> Bits {
        var mask: Bits = 0
        for (bitIndex, character) in pattern.enumerated() where character == "#" {
            mask |= 1 << Bits(bitIndex)
        }
        return mask
    }

    private static func bitmask(fromBitIndices indices: [Int]) -> Bits {
        indices.reduce(0 as Bits) { mask, bitIndex in
            mask | (1 << Bits(bitIndex))
        }
    }

    func minimumButtonPressesToActivate() -> Int? {
        var visited: Set<Bits> = [0]
        var queue: [(state: Bits, steps: Int)] = [(0, 0)]

        while !queue.isEmpty  {
            let (state, steps) = queue.removeFirst()

            if state == activationPattern {
                return steps
            }

            for button in buttons {
                let nextState = state ^ button.bitmask
                if visited.insert(nextState).inserted {
                    queue.append((nextState, steps + 1))
                }
            }
        }

        return nil
    }
}

private extension BinaryInteger {
    @inline(__always) var isOdd: Bool { (self & 1) == 1 }
}

// Part 2 solution stolen from the post:
// https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/
//
// In the Git commit history there is my own solution before this, but it takes
// 45 minutes to run, whereas this takes 270 ms, defeating the Z3 solution.
//
// See the Reddit post for details, but basically the idea is to generate all
// patterns that can be formed by pressing each button either 0 or 1 times.
// Then, the idea is to use repeated application of these patterns to
// recursively halve the remaining target values to find the combination
// correct combination. Pressing the same button an even number of times
// preserves the parity of the affected target values so the same pattern
// can be applied an even number of times and still match the pattern "shape".

extension Machine {
    func minimumButtonPressesToReachJoltageRequirements() -> Int? {
        let target = joltageRequirements.map { Int($0) }
        if target.allSatisfy({ $0 == 0 }) {
            return 0
        }

        let patterns = makePatterns()
        var cache = [[Int]: Int]()

        func minimumPressCount(for target: [Int]) -> Int? {
            if let cached = cache[target] {
                return cached == .max ? nil : cached
            }
            if target.allSatisfy({ $0 == 0 }) {
                cache[target] = 0
                return 0
            }

            var minPresses = Int.max

            for (pattern, patternCost) in patterns {
                let isValid = zip(pattern, target).allSatisfy { patternValue, targetValue in
                    patternValue <= targetValue && patternValue.isOdd == targetValue.isOdd
                }
                guard isValid else { continue }

                let remainingTarget = zip(pattern, target).map { patternValue, targetValue in
                    (targetValue - patternValue) / 2
                }

                guard let remainingPressCount = minimumPressCount(for: remainingTarget) else {
                    continue
                }

                let totalPressCount = patternCost + 2 * remainingPressCount
                if totalPressCount < minPresses {
                    minPresses = totalPressCount
                }
            }

            cache[target] = minPresses
            return minPresses == .max ? nil : minPresses
        }

        return minimumPressCount(for: target)
    }

    private func makePatterns() -> [[Int]: Int] {
        var patterns = [[Int]: Int]()

        for patternLength in 0...buttons.count {
            forEachButtonCombination(length: patternLength) { buttonIndices in
                var pattern = Array(repeating: 0, count: joltageRequirements.count)

                for buttonIndex in buttonIndices {
                    for targetIndex in buttons[buttonIndex].indices {
                        pattern[targetIndex] += 1
                    }
                }

                if patterns[pattern] == nil {
                    patterns[pattern] = patternLength
                }
            }
        }

        return patterns
    }

    private func forEachButtonCombination(
        length: Int,
        handleCombination: ([Int]) -> Void
    ) {
        if length == 0 {
            handleCombination([])
            return
        }

        var indices = [Int]()
        indices.reserveCapacity(length)

        func generateCombinations(startIndex: Int, remainingCount: Int) {
            if remainingCount == 0 {
                handleCombination(indices)
                return
            }

            let upperBound = buttons.count - remainingCount
            if startIndex > upperBound {
                return
            }

            for index in startIndex...upperBound {
                indices.append(index)
                generateCombinations(startIndex: index + 1, remainingCount: remainingCount - 1)
                indices.removeLast()
            }
        }

        generateCombinations(startIndex: 0, remainingCount: length)
    }
}

func readMachines() throws -> [Machine] {
    var machines = [Machine]()

    while let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
        let fields = line
            .split(separator: " ")
            .map { String($0.dropFirst().dropLast()) }

        guard fields.count > 2 else { throw Machine.Failure.invalidInput(line) }

        let integerLists = fields.dropFirst().map { field in
            field.split(separator: ",").compactMap { Int($0) }
        }

        let machine = try Machine(
            activationPattern: fields[0],
            buttons: integerLists.dropLast(),
            joltageRequirements: integerLists.last ?? []
        )
        machines.append(machine)
    }
    return machines
}

let machines = try readMachines()

let activationPresses = machines.reduce(into: 0) { totalPresses, machine in
    totalPresses += machine.minimumButtonPressesToActivate()!
}

print(activationPresses)

let joltagePresses = await withTaskGroup(of: Int.self) { group in
    for machine in machines {
        group.addTask {
            machine.minimumButtonPressesToReachJoltageRequirements()!
        }
    }

    var total = 0
    for await presses in group {
        total += presses
    }
    return total
}

print(joltagePresses)
