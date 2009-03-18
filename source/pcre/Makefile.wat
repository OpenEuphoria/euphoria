#
# Makefile for PCRE to be included into Euphoria
#

CC = wcc386

BASEPATH=.

!include ..\config.wat
!include objects.wat

.c.obj :
    wcc386 -zq -oaxt $<

all: config.h pcre.h $(PCRE_OBJECTS)

config.h: config.h.windows
	copy config.h.windows config.h

pcre.h: pcre.h.windows
	copy pcre.h.windows pcre.h

distclean : .SYMBOLIC clean
	del /f/q config.h pcre.h
	
clean: .SYMBOLIC
	del /f/q *.obj
