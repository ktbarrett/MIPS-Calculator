
OUTPUT_FILENAME=calculator.asm

SOURCE_DIR=src/
MAIN=$(SOURCE_DIR)main.asm
HEADERS=$(SOURCE_DIR)/*.h
PIECES=$(shell find src/ -type f ! -samefile $(MAIN) -name '*.asm' -printf '%p ')

COMMENTS=-e "/^\s*\#/d"
EMPTY=-e "/^\s*$$/d"
INCLUDES=-e "/^\s*.include/d"
GLOBALS=-e "/^\s*.globl/d"
EXCLUDES=$(COMMENTS) $(EMPTY) $(INCLUDES) $(GLOBALS)

# generates single file from source directory
all:
	cat $(HEADERS) $(MAIN) $(PIECES) | sed $(EXCLUDES) > $(OUTPUT_FILENAME)

clean:
	rm $(OUTPUT_FILENAME)
