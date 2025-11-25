# Advent of Code

This repository contains some of my Advent of Code solutions, along with a
[Makefile](Makefile) to quickly build and check solutions in various languages.

## Building

``` sh
cd 2024
make 11
```

## Coding

```
mkdir 2025
cp 2024/Makefile 2025/
cd 2025
cat >simple1.txt # The simple sample input
cat >day1.txt    # The personalized input
echo 'simple1.txt 123' >>answers.txt
vi day1.rb
make 1
echo 'day1.txt 456' >>answers.txt
```

See the top of [Makefile](Makefile) for info about the build system.
