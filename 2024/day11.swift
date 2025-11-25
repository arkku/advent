import Foundation

var cache = [Int: Int]()

@MainActor
func blink(times: Int, stone: Int) -> Int {
    guard times != 0 else { return 1 }

    let state = (times << 56) | stone

    if let cached = cache[state] {
        return cached
    }

    let times = times - 1
    var result: Int

    if stone == 0 {
        result = blink(times: times, stone: 1)
    } else {
        let digitCount = Int(log10(Double(stone))) + 1
        if digitCount % 2 == 0 {
            let divisor = Int(pow(10.0, Double(digitCount / 2)))
            result = blink(times: times, stone: stone / divisor) + blink(times: times, stone: stone % divisor)
        } else {
            result = blink(times: times, stone: stone * 2024)
        }
    }

    cache[state] = result
    return result
}

@MainActor
func main() async {
    let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let stones = line.split(separator: " ").compactMap { Int($0) }

    for times in [25, 75] {
        var count = 0
        for stone in stones {
            count += blink(times: times, stone: stone)
        }
        print(count)
    }
}

await main()
