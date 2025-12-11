import Foundation

final class Machine: Sendable {
    typealias Bits = UInt
    typealias Jolt = Int32 // Tried UInt8 but doesn't work for my input

    enum Failure: Error {
        case noButtons
        case invalidInput(String)
        case joltageRequirementsOverflow([Int])
        case activationPatternTooLong(String)
    }

    private let activationPattern: Bits
    private let buttons: [(bitmask: Bits, indices: [Int])]
    private let joltageRequirements: [Jolt]

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

        self.joltageRequirements = try joltageRequirements.map { joltage in
            guard joltage >= 0 && joltage < Int(Jolt.max) else {
                throw Failure.joltageRequirementsOverflow(joltageRequirements)
            }
            return Jolt(joltage)
        }

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

extension Machine {
    private struct JoltageState: Sendable {
        let machine: Machine
        let target: [Jolt]
        let availableButtons: [Int]

        var isSolved: Bool {
            target.allSatisfy { $0 == 0 }
        }

        var activeTargetIndices: [Int] {
            target.indices.filter { target[$0] > 0 }
        }

        func buttonsAffecting(targetIndex: Int) -> [Int] {
            availableButtons.filter { machine.buttons[$0].indices.contains(targetIndex) }
        }

        func buttonCountAffecting(targetIndex: Int) -> Int {
            availableButtons.reduce(into: 0) { result, buttonIndex in
                if machine.buttons[buttonIndex].indices.contains(targetIndex) {
                    result += 1
                }
            }
        }

        func forcing(buttonIndex: Int, presses: Int) -> JoltageState? {
            var newTarget = target
            for targetIndex in machine.buttons[buttonIndex].indices {
                newTarget[targetIndex] -= Jolt(presses)
                if newTarget[targetIndex] < 0 {
                    return nil
                }
            }
            let newButtons = availableButtons.filter { $0 != buttonIndex }
            return JoltageState(machine: machine, target: newTarget, availableButtons: newButtons)
        }
    }

    func minimumButtonPressesToReachJoltageRequirements() -> Int? {
        minimumPresses(
            for: .init(
                machine: self,
                target: joltageRequirements,
                availableButtons: Array(buttons.indices)
            )
        )
    }

    private func minimumPresses(for state: JoltageState) -> Int? {
        if state.isSolved { return 0 }
        guard !state.availableButtons.isEmpty else { return nil }

        let activeIndices = state.activeTargetIndices

        for targetIndex in activeIndices {
            let affectingButtons = state.buttonsAffecting(targetIndex: targetIndex)

            if affectingButtons.isEmpty {
                return nil
            }

            if affectingButtons.count == 1 {
                // Forced button, since it is the only one affecting this
                let buttonIndex = affectingButtons[0]
                let presses = Int(state.target[targetIndex])

                guard let nextState = state.forcing(buttonIndex: buttonIndex, presses: presses) else {
                    return nil
                }
                guard let rest = minimumPresses(for: nextState) else {
                    return nil
                }
                return presses + rest
            }
        }

        // Choose the target index with fewest buttons affecting it
        var chosenIndex: Int?
        var chosenButtonCount = Int.max
        for targetIndex in activeIndices {
            let count = state.buttonCountAffecting(targetIndex: targetIndex)
            if count < chosenButtonCount {
                chosenButtonCount = count
                chosenIndex = targetIndex
            }
        }
        guard let targetIndex = chosenIndex else { return nil }

        let candidateButtons = state.buttonsAffecting(targetIndex: targetIndex)
        guard !candidateButtons.isEmpty else { return nil }

        let requiredTotal = Int(state.target[targetIndex])

        if candidateButtons.allSatisfy({ buttons[$0].indices.count > 1 }) {
            var indicesAffectedByAllCandidates = Set(buttons[candidateButtons[0]].indices)
            for buttonIndex in candidateButtons.dropFirst() {
                indicesAffectedByAllCandidates.formIntersection(buttons[buttonIndex].indices)
            }
            for affectedIndex in indicesAffectedByAllCandidates {
                if Int(state.target[affectedIndex]) != requiredTotal,
                state.buttonCountAffecting(targetIndex: affectedIndex) == candidateButtons.count {
                    // Contradiction: same buttons affect both targets
                    return nil
                }
            }
        }

        // Brute force all combinations of these buttons such that they add
        // up to the value of this target
        let remainingButtons = state.availableButtons.filter { !candidateButtons.contains($0) }
        var bestSolution: Int?

        forEachCombination(total: requiredTotal, slots: candidateButtons.count) { counts in
            var target = state.target

            for (offset, presses) in counts.enumerated() where presses > 0 {
                let buttonIndex = candidateButtons[offset]
                for index in buttons[buttonIndex].indices {
                    target[index] -= Jolt(presses)
                    if target[index] < 0 {
                        return
                    }
                }
            }

            let nextState = JoltageState(
                machine: self,
                target: target,
                availableButtons: remainingButtons
            )

            guard let rest = minimumPresses(for: nextState) else {
                return
            }

            let totalPresses = counts.reduce(0, +) + rest
            if totalPresses < bestSolution ?? .max {
                bestSolution = totalPresses
            }
        }

        return bestSolution
    }

    private func forEachCombination(total: Int, slots: Int, handler: ([Int]) -> Void) {
        var combination = Array(repeating: 0, count: slots)

        func recurse(position: Int, remaining: Int) {
            if position == slots - 1 {
                combination[position] = remaining
                handler(combination)
                combination[position] = 0
                return
            }

            for value in 0...remaining {
                combination[position] = value
                recurse(position: position + 1, remaining: remaining - value)
            }
            combination[position] = 0
        }

        recurse(position: 0, remaining: total)
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

let isHardInput = machines.count > 100
if isHardInput {
    print("Warning: The following calculation will take a long time")
}

var solved = 0

let joltagePresses = await withTaskGroup(of: Int.self) { group in
    for machine in machines {
        group.addTask {
            machine.minimumButtonPressesToReachJoltageRequirements()!
        }
    }

    var total = 0
    for await presses in group {
        total += presses
        if isHardInput {
            solved += 1
            print("\(solved)/\(machines.count)")
        }
    }
    return total
}

print(joltagePresses)
