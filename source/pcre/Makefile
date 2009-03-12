#
# Makefile for PCRE to be included into Euphoria
#

CFLAGS=-O2

include objects.mak

all: config.h pcre.h $(PCRE_OBJECTS)

.PHONY: mingw mingwconfigh mingwpcreh

mingw: mingwconfigh mingwpcreh $(PCRE_OBJECTS)

mingwconfigh: config.h.windows
	cp config.h.windows config.h

mingwpcreh: pcre.h.windows
	cp pcre.h.windows pcre.h

config.h: config.h.unix
	cp config.h.unix config.h

pcre.h: pcre.h.unix
	cp pcre.h.unix pcre.h

.PHONY: clean distclean

distclean :
	rm -f config.h pcre.h

clean:
	rm -f *.o config.h pcre.h
