#
# Makefile for JSMN to be included into Euphoria
#

CFLAGS=-O2 $(EOSTYPE) -D HAVE_CONFIG_H -D NO_RECURSE $(MSIZE) $(EOSFLAGS) $(FPIC)

include objects.mak
include $(CONFIG)

PREFIXED_JSMN_OBJECTS = $(addprefix $(BUILDDIR)/jsmn$(FPIC)/,$(JSMN_OBJECTS))

all: $(BUILDDIR)/jsmn$(FPIC) config.h jsmn.h $(PREFIXED_JSMN_OBJECTS)

$(BUILDDIR)/jsmn$(FPIC) :
	-mkdir $(BUILDDIR)/jsmn$(FPIC)

$(PREFIXED_JSMN_OBJECTS) : $(patsubst %.o,%.c,$(JSMN_OBJECTS))
	$(JSMN_CC) $(CFLAGS) -c $(patsubst $(BUILDDIR)/jsmn$(FPIC)/%,%,$*).c -o $*.o

.PHONY: clean distclean

distclean : clean
	

clean:
	rm -f $(PREFIXED_JSMN_OBJECTS)
