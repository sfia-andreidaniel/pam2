.PHONY: build

SHELL := /bin/bash
OPTIMIZE ?= -O3
LINKING ?= -XX
HINTS ?= -vwen
INCLUDES := -Fuinc/indy -Fuinc/lib -Fuserver -Fuclient

build:: clean
	@echo "BUILDING SERVER"
	@fpc pam2d.pas -vwen -Mobjfpc $(OPTIMIZE) $(LINKING) $(INCLUDES) | grep -v "Compiling " | grep -v "Hint: " | grep -v "Warning: " | grep -v "Writing Resource String"
	@echo "BUILDING CLIENT"
	@fpc pam2.pas  -vwen -Mobjfpc $(OPTIMIZE) $(LINKING) $(INCLUDES) | grep -v "Compiling " | grep -v "Hint: " | grep -v "Warning: " | grep -v "Writing Resource String"

clean::
	@rm -f inc/lib/*.o server/*.o *.o inc/indy/*.o \
	inc/lib/*.ppu inc/indy/*.ppu server/*.ppu *.ppu \
	pam2d pam2d.exe pam2d.o install/*.msi \
	pam2 pam2.exe pam2.o client/*.o client/*.ppu