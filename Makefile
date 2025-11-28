# Makefile for Advent of Code (or similar daily programming puzzles).
# Kimmo Kulovesi, https://github.com/arkku
#
# This allows you to type `make 3` to compile and run all of your
# solutions for the puzzles of day 3 against both the simple test
# case and the real input. It will time each run, and it will show
# the correct answer under each run (from the file `answers.txt`,
# which you must fill in).
#
# NOTE: This does _not_ fetch anything from the Advent of Code servers
# or anywhere else. YOU need to populate the input data and the correct
# answers yourself. But this helps while working on it.
#
# You can add support for more languages quite easily, just follow
# the patterns of the (many) existing ones. The shell parts have
# been written for `zsh`, but you can change to `SHELL = bash`
# or whatever (the time format will just look worse).
#
# Name each program `dayX.ext`, e.g., `day1.c` or `day14.rb`. There
# can be multiple programs for each day in different languages. If
# there is a separate program for part 1 and part 2, add `a` after
# the day for part 1, and `b` after the day for part 2.
#
# Put the simple test case input from the site into `simpleX.txt`,
# where X is the day number. Put your personal, real, input
# into `dayX.txt`.
#
# To display the correct answers under each run, make `answers.txt`
# in the format:
#
#     simple1.txt   11      31
#     day1.txt      part1
#      …
#
# If you only know the answer for part 1, it's ok to omit part 2.
# 
# So, you might have a directory containing:
#     Makefile
#     day1.go
#     day4.c
#     day4a.rb
#     day4b.py
#     simple1.txt
#     day1.txt
#     simple4.txt
#     day4.txt
#     answers.txt
#
# Then, running `make 1` would compile and run `day1.go` against
# both `simple1.txt` and `day1.txt` (passed from stdin). Similarly,
# `make 4` would run compile and run `day4.c`, and just execute
# `day4a.rb` and `day4b.py` (which need to bo executable, i.e.,
# use the `#!` shebang and `chmod a+x`), all against both inputs.
#
# To run only a specific language for a day, you can do something
# like `make 4rb` to only run the Ruby implementation.
#
# As usual, use at your own risk only!

# Change here if you don't have zsh:
SHELL = zsh

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

COMPILED_SOURCES := $(wildcard day*.c day*.go day*.swift day*.cr day*.rs day*.zig day*.hs)
BINARIES := $(subst .,-,$(COMPILED_SOURCES))
SCRIPTS := $(wildcard day*.rb day*.py day*.ts day*.js day*.sh day*.pl day*.exs day*.erl day*.clj day*.awk day*.lua)
RUNNABLES := $(BINARIES) $(SCRIPTS)
EXPECTED := $(MAKEFILE_DIR)/expected.sh
HELPERS = $(EXPECTED)

GHC := $(shell if command -v stack >/dev/null 2>&1; then echo 'stack ghc --'; else echo 'ghc'; fi)
SWIFT_BUILD_FLAGS = --configuration release

.PHONY: all clean
all: $(HELPERS) $(BINARIES)

clean:
	@rm -vf $(BINARIES) day\*.dwarf day\*.o day\*.hi
	@rm -rf .build target

day%-c: day%.c
	clang -std=c23 -Wall -pedantic -O3 -ffast-math -I. -I.. -o $@ $<

day%-go: day%.go
	go build -trimpath -o $@ $<

day%-swift: day%.swift
	@#swift build $(SWIFT_BUILD_FLAGS) --quiet && cp $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$@ $@
	@swiftc -O -o $@ $<

day%-cr: day%.cr
	crystal build --release -o $@ $<
	
day%-rs: day%.rs
	rustc -C opt-level=3 -o $@ $<

day%-zig: day%.zig
	zig build-exe -OReleaseFast $< --name $@
	@rm -f $@.o

day%-hs: day%.hs
	$(GHC) -O2 -o $@ $<
	@rm -f day$*.hi day$*.o

$(EXPECTED):
	@echo '#!/bin/sh' > $@
	@echo 'exec awk -v file="$$1" -v bin="$$2" '\' >> $@
	@echo '    BEGIN {' >> $@
	@echo '        part2 = (bin ~ /[0-9][b-z][.-]/)' >> $@
	@echo '        part1 = (bin ~ /[0-9]a[.-]/)' >> $@
	@echo '    }' >> $@
	@echo '    $$1 == file && $$NF >= 2 {' >> $@
	@echo '        if (!part2 && $$2) {' >> $@
	@echo '            printf("%-13s\\tpart 1 expected\\n", $$2);' >> $@
	@echo '        }' >> $@
	@echo '        if (!part1 && $$3) {' >> $@
	@echo '            printf("%-13s\\tpart 2 expected\\n", $$3);' >> $@
	@echo '        }' >> $@
	@echo '    }'\'' answers.txt' >> $@
	chmod a+x $@

get_day = $(patsubst %a,%, $(patsubst %c,%, $(patsubst %b,%, $(subst day,,$(firstword $(subst -, ,$(basename $(notdir $(1)))))))))

DAYS := $(sort $(foreach r,$(RUNNABLES),$(call get_day,$(r))))

$(foreach r,$(RUNNABLES), \
	$(eval DAY_RUNNABLES_$(call get_day,$(r)) += $(r)) \
)

$(foreach b,$(BINARIES), \
	$(eval DAY_BINARIES_$(call get_day,$(b)) += $(b)) \
)

$(foreach d,$(DAYS), \
	$(foreach e,$(DAY_EXTENSIONS_$(d)),$(eval $(call run_day_extension_template,$(d),$(e)))))

define run_single_input_template
.PHONY: runnable_$(notdir $(1))_input_$(2)
runnable_$(notdir $(1))_input_$(2): $(1) $(2)
	@echo
	@echo -e "> \033[1m./$(1) <$(2)\033[0m"
	@{ TIMEFMT=$$$$'\n$(1) \t%*U user %*S system %P cpu %*E total\t%M KB'; time ./$(1) <$(2); } 2> >( { if [ -t 2 ]; then while read line; do echo -en "\033[90m"; echo -n "$$$$line"; echo -e "\033[0m"; done; else cat; fi; } >&2 )
	@echo -e "\033[90m`$(EXPECTED) $(2) $(1)`\033[0m"
endef

$(foreach r,$(RUNNABLES),$(eval $(call run_single_input_template,$(r),simple$(call get_day,$(r)).txt)))
$(foreach r,$(RUNNABLES),$(eval $(call run_single_input_template,$(r),day$(call get_day,$(r)).txt)))

define run_day_template
.PHONY: $(1)
$(1): $(HELPERS) $(foreach r,$(DAY_RUNNABLES_$(1)),runnable_$(notdir $(r))_input_simple$(1).txt)
$(1): $(HELPERS) $(foreach r,$(DAY_RUNNABLES_$(1)),runnable_$(notdir $(r))_input_day$(1).txt)
endef

$(foreach d,$(DAYS),$(eval $(call run_day_template,$(d))))

get_extension = $(lastword $(subst ., ,$(subst -, ,$(notdir $(1)))))
$(foreach d,$(DAYS),$(eval DAY_EXTENSIONS_$(d) = $(sort $(foreach r,$(DAY_RUNNABLES_$(d)),$(call get_extension,$(r))))))

define run_day_extension_template
.PHONY: $(1)$(2)
$(1)$(2): $(HELPERS) $(foreach r,$(filter %$(2),$(DAY_RUNNABLES_$(1))),runnable_$(notdir $(r))_input_simple$(1).txt)
$(1)$(2): $(HELPERS) $(foreach r,$(filter %$(2),$(DAY_RUNNABLES_$(1))),runnable_$(notdir $(r))_input_day$(1).txt)
endef

$(foreach d,$(DAYS), $(foreach e,$(DAY_EXTENSIONS_$(d)),$(eval $(call run_day_extension_template,$(d),$(e)))))
