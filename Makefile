.PHONY: build test clean coverage

build:
	odin build . -file -out:diceroll

test:
	odin test . -file -all-packages

clean:
	rm -f diceroll