#
# Makefile for PCRE to be included into Euphoria
#

CFLAGS=-O3 $(EOSTYPE) -D HAVE_CONFIG_H -D NO_RECURSE $(MSIZE) $(EOSFLAGS) $(FPIC)

include objects.mak
include $(CONFIG)

PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre$(FPIC)/,$(PCRE_OBJECTS))

all: $(BUILDDIR)/pcre$(FPIC) config.h pcre.h $(PREFIXED_PCRE_OBJECTS)

$(BUILDDIR)/pcre$(FPIC) :
	-mkdir $(BUILDDIR)/pcre$(FPIC)

$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,%.c,$(PCRE_OBJECTS))
	$(PCRE_CC) $(CFLAGS) -c $(patsubst $(BUILDDIR)/pcre$(FPIC)/%,%,$*).c -o $*.o

.PHONY: clean distclean

distclean : clean
	

clean:
	rm -f $(PREFIXED_PCRE_OBJECTS)
