use std::collections::HashMap;
use std::io::{self, BufRead};

fn blink(times: u8, stone: i64, cache: &mut HashMap<u64, i64>) -> i64 {
    if times == 0 {
        return 1;
    }

    let key = ((times as u64) << 56) | (stone as u64);
    if let Some(&result) = cache.get(&key) {
        return result;
    }

    let result = if stone == 0 {
        blink(times - 1, 1, cache)
    } else {
        let digit_count = (stone as f64).log10().floor() as u32 + 1;
        if digit_count % 2 == 0 {
            let divisor = 10_i64.pow(digit_count / 2);
            let lhs = stone / divisor;
            let rhs = stone % divisor;
            blink(times - 1, lhs, cache) + blink(times - 1, rhs, cache)
        } else {
            blink(times - 1, stone * 2024, cache)
        }
    };

    cache.insert(key, result);
    result
}

fn main() {
    let stdin = io::stdin();
    let mut input = String::new();

    if let Err(err) = stdin.lock().read_line(&mut input) {
        eprintln!("read_line: {}", err);
        return;
    }

    let stones: Vec<i64> = input
        .trim()
        .split_whitespace()
        .map(|s| s.parse().unwrap())
        .collect();

    for &times in &[25, 75] {
        let mut cache = HashMap::new();
        let count: i64 = stones.iter().map(|&stone| blink(times, stone, &mut cache)).sum();
        println!("{}", count);
    }
}
