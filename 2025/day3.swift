import Foundation

/// - Precondition: `bank.count >= digitCount`
func maxJoltage(digitCount: Int, bank: ArraySlice<Int>, joltage: Int = 0) -> Int {
    guard digitCount > 0 else { return joltage }

    let remainingDigitCount = digitCount - 1
    let prefixLengthLeavingEnoughDigits = max(bank.count - remainingDigitCount, 0)

    let digit = bank
        .prefix(prefixLengthLeavingEnoughDigits)
        .enumerated()
        .max { a, b in
            // It's unclear whether `max(by:)` is guaranteed to be stable,
            // hence the tiebreaker (but it does seem to be stable in practice)
            a.element < b.element || (a.element == b.element && a.offset > b.offset)
        }

    guard let digit else {
        assertionFailure("Bank too short for \(digitCount) digits")
        return joltage
    }

    return maxJoltage(
        digitCount: remainingDigitCount,
        bank: bank.dropFirst(digit.offset + 1),
        joltage: joltage * 10 + digit.element
    )
}

var banks: [[Int]] = []
while let line = readLine() {
    let digitCount = line.compactMap { $0.wholeNumberValue }
    guard !digitCount.isEmpty else { continue }
    banks.append(digitCount)
}

for digitCount in [2, 12] {
    let sum = banks.reduce(into: 0) { sum, bank in
        sum += maxJoltage(digitCount: digitCount, bank: .init(bank))
    }
    print(sum)
}
