package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
)

var cache = make(map[uint64]uint64)

func blink(times uint64, stone uint64) uint64 {
	if times == 0 {
		return 1
	}

	state := times<<56 | stone

	if cached, found := cache[state]; found {
		return cached
	}

	times--
	var result uint64

	if stone == 0 {
		result = blink(times, 1)
	} else if digitCount := int(math.Log10(float64(stone)) + 1); digitCount%2 == 0 {
		divisor := uint64(math.Pow(10, float64(digitCount/2)))
		result = blink(times, stone/divisor) + blink(times, stone%divisor)
	} else {
		result = blink(times, stone*2024)
	}

	cache[state] = result
	return result
}

func main() {
	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	input = strings.TrimSpace(input)

	stoneFields := strings.Fields(input)
	stones := make([]uint64, len(stoneFields))
	for i, stone := range stoneFields {
		stones[i], _ = strconv.ParseUint(stone, 10, 64)
	}

	for _, times := range []uint64{25, 75} {
		var count uint64
		for _, stone := range stones {
			count += blink(times, stone)
		}
		fmt.Println(count)
	}
}
