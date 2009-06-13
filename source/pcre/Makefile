#
# Makefile for PCRE to be included into Euphoria
#

CFLAGS=-O2 $(EOSTYPE) -D NO_RECURSE

include objects.mak
include $(CONFIG)

PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre/,$(PCRE_OBJECTS))

all: $(BUILDDIR)/pcre config.h pcre.h $(PREFIXED_PCRE_OBJECTS)

$(BUILDDIR)/pcre :
	-mkdir $(BUILDDIR)/pcre

$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,%.c,$(PCRE_OBJECTS))
	$(CC) $(CFLAGS) -c $(patsubst $(BUILDDIR)/pcre/%,%,$*).c -o $*.o
	
.PHONY: clean distclean

distclean : clean
	

clean:
	rm -f $(PREFIXED_PCRE_OBJECTS)
