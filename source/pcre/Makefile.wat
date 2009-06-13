#
# Makefile for PCRE to be included into Euphoria
#

CC = wcc386

BASEPATH=$(BUILDDIR)\pcre

!include $(CONFIG)
!include objects.wat

all: config.h pcre.h $(BASEPATH) $(PCRE_OBJECTS)

distclean : .SYMBOLIC clean

clean: .SYMBOLIC 
	-del /f/q $(PCRE_OBJECTS)

# I wanted to put $(BASEPATH) here as a dependency for .c files but
# watcom doesn't provide that functionality in inplicit rules... (sigh)
.c.obj : 
    wcc386 $(EOSTYPE) -zq -oaxt  -DNO_RECURSE $< -fo=$@
	
$(BASEPATH) : .EXISTSONLY
    mkdir $(BASEPATH)
	
