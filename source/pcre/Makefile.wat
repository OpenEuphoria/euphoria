#
# Makefile for PCRE to be included into Euphoria
#

CC = wcc386

BASEPATH=$(BUILDDIR)\pcre

!include $(CONFIG)
!include objects.wat
!ifeq DEBUG 1
PCREDEBUG=/d2
!endif

all: $(BASEPATH) $(PCRE_OBJECTS) 

# I wanted to put $(BASEPATH) here as a dependency for .c files but
# watcom doesn't provide that functionality in inplicit rules... (sigh)
.c.obj : .AUTODEPEND
    wcc386 $(EOSTYPE) /zp4 /w0 $(CPU_FLAG) /ol $(PCREDEBUG) -zq -oaxt  -DHAVE_CONFIG_H -DNO_RECURSE $< -fo=$@

$(BASEPATH) : .EXISTSONLY $(BUILDDIR)
	mkdir $(BASEPATH)
