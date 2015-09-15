.PHONY: build

SHELL := /bin/bash
OPTIMIZE ?= -O3
LINKING ?= -XX
HINTS ?= -vwen
INCLUDES := -Fuinc/indy -Fuinc/lib -Fuserver

build:: clean
	@fpc pam2d.pas -vwen -Mobjfpc $(OPTIMIZE) $(LINKING) $(INCLUDES) | grep -v "Compiling " | grep -v "Hint: " | grep -v "Warning: " | grep -v "Writing Resource String"
	@chmod 755 ./pam2.js

clean::
	@rm -f inc/lib/*.o server/*.o *.o inc/indy/*.o \
	inc/lib/*.ppu inc/indy/*.ppu server/*.ppu *.ppu \
	pam2d pam2d.exe pam2d.o install/*.msi