import qualified Data.Map.Strict as Map
import Data.List.Split (wordsBy)
import Text.Read (readMaybe)
import System.IO (hFlush, stdout)

type Cache = Map.Map (Int, Integer) Integer

blink :: Int -> Integer -> Cache -> (Integer, Cache)
blink 0 _ cache = (1, cache)
blink times stone cache =
    case Map.lookup state cache of
        Just cached -> (cached, cache)
        Nothing ->
            let (result, newCache) = if stone == 0
                    then blink (times - 1) 1 cache
                    else
                        let digitCount = floor (logBase 10 (fromIntegral stone)) + 1 :: Int
                        in if digitCount `mod` 2 == 0
                            then
                                let divisor = 10 ^ (digitCount `div` 2)
                                    (part1, cache1) = blink (times - 1) (stone `div` divisor) cache
                                    (part2, cache2) = blink (times - 1) (stone `mod` divisor) cache1
                                in (part1 + part2, cache2)
                            else blink (times - 1) (stone * 2024) cache
                updatedCache = Map.insert state result newCache
            in (result, updatedCache)
  where
    state = (times, stone)

main :: IO ()
main = do
    input <- getLine
    let stones = map readInteger (words input)
    let timesList = [25, 75]
    let initialCache = Map.empty

    mapM_ (\times ->
        let (count, _) = foldl (\(acc, cache) stone ->
                let (res, newCache) = blink times stone cache
                in (acc + res, newCache)
              ) (0, initialCache) stones
        in putStrLn $ show count
      ) timesList
  where
    readInteger :: String -> Integer
    readInteger s = case readMaybe s of
        Just n  -> n
        Nothing -> error "Failed to read input"
