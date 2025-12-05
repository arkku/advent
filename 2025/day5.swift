import Foundation

func readMergedAndSortedRanges() -> [ClosedRange<UInt64>] {
    var ranges = [ClosedRange<UInt64>]()

    while let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
        let fields = line.split(separator: "-" , omittingEmptySubsequences: false)
        guard fields.count == 2 else { fatalError("Invalid field count") }
        guard let start = UInt64(fields[0]), let end = UInt64(fields[1]) else {
            fatalError("Non-integer fields")
        }
        guard start <= end else { fatalError("Invalid range") }
        ranges.append(start...end)
    }

    ranges.sort { a, b in
        a.lowerBound < b.lowerBound || (a.lowerBound == b.lowerBound && a.upperBound < b.upperBound)
    }

    var mergedRanges = [ClosedRange<UInt64>]()
    for range in ranges {
        if let previous = mergedRanges.last,
        previous.contains(range.lowerBound) || range.contains(previous.upperBound) {
            mergedRanges.removeLast()
            mergedRanges.append((previous.lowerBound)...max(previous.upperBound, range.upperBound))
        } else {
            mergedRanges.append(range)
        }
    }

    return mergedRanges
}

extension ClosedRange where Bound: Numeric {
    var length: Bound { upperBound - lowerBound + 1 }
}

let ranges = readMergedAndSortedRanges()

var freshCount = 0
while let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
    guard let ingredient = UInt64(line) else { fatalError("Invalid ingredient") }

    for range in ranges {
        guard range.lowerBound <= ingredient else { break }
        if range.contains(ingredient) {
            freshCount += 1
            break
        }
    }
}

print("\(freshCount)")

let freshIdsCount = ranges.reduce(into: 0) { sum, range in
    sum += range.length
}

print("\(freshIdsCount)")
