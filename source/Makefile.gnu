# GNU Makefile for Euphoria (Linux and FreeBSD)
#
# NOTE: This is meant to be used with GNU make,
#       so on BSD, you should use gmake instead
#       of make
#
# Syntax:
#
#   Configure the make system :  ./configure
#
#   You must run configure
#   before building
#
#  Configure options:
#
#     --without-euphoria      Use this option if you are building Euphoria 
#		     with only a C compiler.
# 
#     --eubin <dir>   Use this option to specify the location of the interpreter
#		     binary to use to translate the front end.  The default
#		     is ../bin
#
#     --managed-mem   Use this option to turn EUPHORIA's memory cache on in
#		     the targets
#
#     --debug	 Use this option to turn on debugging symbols
#
#
#     --full	  Use this option to so EUPHORIA doesn't report itself
#		     as a development version.
#
#     --plat value   set the OS that the translator will translate the code to.
#            values can be: WIN, OSX, LINUX, FREEBSD, SUNOS, OPENBSD or NETBSD.
#
#     --watcom   Use this so the translator will create C code for Watcom C.
#
#     --cc  value         set this to the name of your GNU C compiler file name if its 
#                        name is not 'gcc'
#
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean
#        translated files
#   Everything                :  make
#   Interpreter          (eui):  make interpreter
#   Translator           (euc):  make translator
#   Translator Library  (eu.a):  make library
#   Backend              (eub):  make eub
#   Run Unit Tests            :  make test
#   Run Unit Tests with eu.ex :  make testeu
#   Code Page Database        :  make code-page-db
#
#   Html Documentation        :  make htmldoc 
#   PDF Documentation         :  make pdfdoc
#
#   Note that Html and PDF Documentation require eudoc and creolehtml
#   PDF docs also require htmldoc
#
# In order to achieve compatibility among 9 platforms
# please follow these Code standards:


ifndef CONFIG
CONFIG = Makefile.eu
endif

PCRE_CC=$(CC)

include $(CONFIG)
include $(TRUNKDIR)/source/pcre/objects.mak

ifeq "$(RELEASE)" "1"
RELEASE_FLAG = -D EU_FULL_RELEASE
endif

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EBACKEND
BACKEND_FLAGS = -DBACKEND
endif

ifeq "$(EBSD)" "1"
  LDLFLAG=
  EBSDFLAG=-DEBSD -DEBSD62
  SEDFLAG=-Ei
  ifeq "$(EOSX)" "1"
    LDLFLAG=-lresolv
    EBSDFLAG=-DEBSD -DEBSD62 -DEOSX
  endif
  ifeq "$(ESUNOS)" "1"
    LDLFLAG=-lsocket -lresolv -lnsl
    EBSDFLAG=-DEBSD -DEBSD62 -DESUNOS
  endif
  ifeq "$(EOPENBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DEOPENBSD
  endif
  ifeq "$(ENETBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DENETBSD
  endif
else
  LDLFLAG=-ldl -lresolv -lnsl
  PREREGEX=$(FROMBSDREGEX)
  SEDFLAG=-ri
endif
LDLFLAG+= -pthread
ifeq "$(EMINGW)" "1"
	EOSTYPE=-DEWINDOWS
	EBSDFLAG=-DEMINGW
	LDLFLAG=-lws2_32
	SEDFLAG=-ri
	EOSFLAGS=-mno-cygwin -mwindows
	EOSFLAGSCONSOLE=-mno-cygwin
	ifdef EDEBUG
		EOSMING=
	else
		EOSMING=-ffast-math -O3 -Os
	endif
	EBACKENDU=eubw.exe
	EBACKENDC=eub.exe
	EECU=euc.exe
	EEXU=eui.exe
	EEXUW=euiw.exe
	EECUA=eu.a
	ifeq "$(MANAGED_MEM)" "1"
		MEM_FLAGS=
	else
		MEM_FLAGS=-DESIMPLE_MALLOC
	endif
	PCRE_CC=gcc
else
	EOSTYPE=-DEUNIX
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSMING=-O2
	EBACKENDU=eub
	EBACKENDC=eub
	EECU=euc
	EEXU=eui
	EECUA=eu.a
	MEM_FLAGS=-DESIMPLE_MALLOC
endif

ifdef EDEBUG
DEBUG_FLAGS=-g3 -O0 -Wall
CALLC_DEBUG=-g3
EC_DEBUG=-D DEBUG
else
DEBUG_FLAGS=-fomit-frame-pointer $(EOSMING)
endif

ifdef EPROFILE
PROFILE_FLAGS=-pg
ifndef EDEBUG
DEBUG_FLAGS=$(EOSMING)
endif
endif

ifeq  "$(ELINUX)" "1"
EBSDFLAG=-DELINUX
endif

ifeq  "$(EUBIN)" ""
EXE=$(EEXU)
else
EXE=$(EUBIN)/$(EEXU)
endif
INCDIR=-i $(TRUNKDIR)/include

ifdef PLAT
TARGETPLAT=-plat $(PLAT)
endif

ifeq "$(ARCH)" "x86"
BE_CALLC = be_callc
MSIZE=-m32
else
BE_CALLC = be_callc_conly
MSIZE=
endif

ifndef ECHO
ECHO=/bin/echo
endif

ifeq "$(EUDOC)" ""
EUDOC=eudoc
endif

ifeq "$(CREOLEHTML)" ""
CREOLEHTML=creolehtml
endif

ifeq "$(TRANSLATE)" "euc"
	TRANSLATE=$(EECU)
else
	TRANSLATE=$(EXE) $(INCDIR) $(EC_DEBUG) $(TRUNKDIR)/source/ec.ex
endif

FE_FLAGS =  $(MSIZE) -pthread -c -w -fsigned-char $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/ $(PROFILE_FLAGS) -DARCH=$(ARCH)
BE_FLAGS =  $(MSIZE) -pthread  -c -w $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(DEBUG_FLAGS) $(MEM_FLAGS) $(PROFILE_FLAGS) -DARCH=$(ARCH)

EU_CORE_FILES = \
	block.e \
	common.e \
	emit.e \
	error.e \
	fwdref.e \
	inline.e \
	keylist.e \
	main.e \
	msgtext.e \
	mode.e \
	opnames.e \
	parser.e \
	pathopen.e \
	platform.e \
	preproc.e \
	reswords.e \
	scanner.e \
	scinot.e \
	shift.e \
	symtab.e 

EU_INTERPRETER_FILES = \
	backend.e \
	c_out.e \
	cominit.e \
	compress.e \
	global.e \
	intinit.e \
	int.ex

EU_TRANSLATOR_FILES = \
	buildsys.e \
	c_decl.e \
	c_out.e \
	cominit.e \
	compile.e \
	compress.e \
	global.e \
	traninit.e \
	ec.ex

EU_BACKEND_RUNNER_FILES = \
	backend.e \
	il.e \
	cominit.e \
	compress.e \
	error.e \
	intinit.e \
	mode.e \
	reswords.e \
	pathopen.e \
	common.e \
	backend.ex
	
PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre/,$(PCRE_OBJECTS))
	
EU_BACKEND_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_execute.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_main.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rterror.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_syncolor.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_symtab.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rev.o \
	$(PREFIXED_PCRE_OBJECTS)

EU_LIB_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rev.o \
	$(PREFIXED_PCRE_OBJECTS)
	

STDINCDIR = $(TRUNKDIR)/include/std

EU_STD_INC = \
	$(wildcard $(STDINCDIR)/*.e) \
	$(wildcard $(STDINCDIR)/unix/*.e) \
	$(wildcard $(STDINCDIR)/net/*.e) \
	$(wildcard $(STDINCDIR)/win32/*.e)

DOCDIR = $(TRUNKDIR)/docs
EU_DOC_SOURCE = \
	$(EU_STD_INC) \
	$(DOCDIR)/manual.af \
	$(wildcard $(DOCDIR)/*.txt)

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all : interpreter translator library backend code-page-db

BUILD_DIRS=$(BUILDDIR)/intobj/back $(BUILDDIR)/transobj/back $(BUILDDIR)/libobj/back $(BUILDDIR)/backobj/back $(BUILDDIR)/intobj/ $(BUILDDIR)/transobj/ $(BUILDDIR)/libobj/ $(BUILDDIR)/backobj/

distclean : clean
	-rm -f $(CONFIG)
	-rm -fr $(BUILD_DIRS)
	-rm -f Makefile

clean : 	
	-rm -fr $(BUILDDIR)/intobj
	-rm -fr $(BUILDDIR)/transobj
	-rm -fr $(BUILDDIR)/libobj
	-rm -fr $(BUILDDIR)/backobj
	-rm -f $(BUILDDIR)/$(EEXU) $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA) $(BUILDDIR)/$(EBACKENDU) $(BUILDDIR)/$(DEB_SOURCE_DIR).tar.gz
ifeq "$(MINGW)" "1"
	-rm -f $(BUILDDIR)/{$(EBACKENDC),$(EEXUW)}
endif
	$(MAKE) -C pcre CONFIG=../$(CONFIG) clean
	
clobber : distclean
	-rm -fr $(BUILDDIR)

.PHONY : clean distclean clobber all htmldoc

library : builddirs
	$(MAKE) $(BUILDDIR)/$(EECUA) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
$(BUILDDIR)/$(EECUA) : $(EU_LIB_OBJECTS)
	ar -rc $(BUILDDIR)/$(EECUA) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)

builddirs : svn_rev
	mkdir -p $(BUILD_DIRS) 

svn_rev : 
	-$(EXE) -i ../include revget.ex -root ..

code-page-db : $(BUILDDIR)/ecp.dat

$(BUILDDIR)/ecp.dat : interpreter
	$(BUILDDIR)/eui -i $(TRUNKDIR)/include $(TRUNKDIR)/bin/buildcpdb.ex -p$(TRUNKDIR)/source/codepage -o$(BUILDDIR)

interpreter : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

translator : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EECU) OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

.PHONY : library
.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev
.PHONY : code-page-db

euisource : $(BUILDDIR)/intobj/main-.c
euisource :  EU_TARGET = int.ex
eucsource : $(BUILDDIR)/transobj/main-.c
eucsource :  EU_TARGET = ec.ex
backendsource : $(BUILDDIR)/backobj/main-.c
backendsource :  EU_TARGET = backend.ex
source : builddirs
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

SVN_REV=xxx
SOURCEDIR=euphoria-r$(SVN_REV)
source-tarball : source
	rm -rf $(SOURCEDIR)
	mkdir -p $(SOURCEDIR)
	cp -r $(BUILDDIR)/intobj   $(SOURCEDIR)
	cp -r $(BUILDDIR)/transobj $(SOURCEDIR)
	cp -r $(BUILDDIR)/backobj  $(SOURCEDIR)
	cp -r $(BUILDDIR)/libobj   $(SOURCEDIR)
	cp be_*.c       $(SOURCEDIR)
	cp int.ex       $(SOURCEDIR)
	cp ec.ex        $(SOURCEDIR)
	cp backend.ex   $(SOURCEDIR)
	cp *.e          $(SOURCEDIR)
	cp Makefile     $(SOURCEDIR)
	cp Makefile.gnu $(SOURCEDIR)
	cp Makefile.*s  $(SOURCEDIR)
	cp configure    $(SOURCEDIR)
	cp ../include/euphoria.h $(SOURCEDIR)
	cp *.h          $(SOURCEDIR)
	
.PHONY : euisource
.PHONY : eucsource
.PHONY : backendsource
.PHONY : source

$(BUILDDIR)/$(EEXU) :  EU_TARGET = int.ex
$(BUILDDIR)/$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(BUILDDIR)/$(EEXU) :  EU_OBJS = $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
endif
	
$(BUILDDIR)/$(EECU) :  OBJDIR = transobj
$(BUILDDIR)/$(EECU) :  EU_TARGET = ec.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(BUILDDIR)/$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EECU) : $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EU_TRANSLATOR_OBJECTS) $(DEBUG_FLAGS) $(PROFILE_FLAGS) $(EU_BACKEND_OBJECTS) $(MSIZE) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EECU)

backend : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)  EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EBACKENDU) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

$(BUILDDIR)/$(EBACKENDU) : OBJDIR = backobj
$(BUILDDIR)/$(EBACKENDU) : EU_TARGET = backend.ex
$(BUILDDIR)/$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(BUILDDIR)/$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EBACKENDU) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EBACKENDU) $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDU)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EBACKENDC)
endif

$(BUILDDIR)/euphoria.txt : $(EU_DOC_SOURCE)
	cd ../docs/ && $(EUDOC)  -v -a manual.af -o $(BUILDDIR)/euphoria.txt

$(BUILDDIR)/html/index.html : $(BUILDDIR)/euphoria.txt $(DOCDIR)/offline-template.html
	-mkdir -p $(BUILDDIR)/html/images
	-mkdir -p $(BUILDDIR)/html/js
	 $(CREOLEHTML) -A=ON -d=$(TRUNKDIR)/docs/ -t=offline-template.html -o$(BUILDDIR)/html $(BUILDDIR)/euphoria.txt
	cp $(DOCDIR)/style.css $(BUILDDIR)/html
	cp $(DOCDIR)/*js $(BUILDDIR)/html/js
	cp $(DOCDIR)/html/images/* $(BUILDDIR)/html/images

htmldoc : $(BUILDDIR)/html/index.html

$(BUILDDIR)/euphoria-pdf.txt : $(BUILDDIR)/euphoria.txt
	sed -e "s/splitlevel = 2/splitlevel = 0/" $(BUILDDIR)/euphoria.txt > $(BUILDDIR)/euphoria-pdf.txt

$(BUILDDIR)/pdf/index.html : $(BUILDDIR)/euphoria-pdf.txt
	-mkdir -p $(BUILDDIR)/pdf
	$(CREOLEHTML) -A=ON -d=$(TRUNKDIR)/docs/ -t=offline-template.html -o$(BUILDDIR)/pdf -htmldoc $(BUILDDIR)/euphoria-pdf.txt
# 	cd $(TRUNKDIR)/docs && $(CREOLEHTML) -A=ON -t=offline-template.html -o$(BUILDDIR)/pdf $(BUILDDIR)/euphoria-pdf.txt

$(BUILDDIR)/euphoria-4.0.pdf : $(BUILDDIR)/euphoria-pdf.txt $(BUILDDIR)/pdf/index.html
	htmldoc -f $(BUILDDIR)/euphoria-4.0.pdf --book $(BUILDDIR)/pdf/eu400*.html $(BUILDDIR)/pdf/index.html

pdfdoc : $(BUILDDIR)/euphoria-4.0.pdf

test : EUDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)	
test : C_INCLUDE_PATH=$(TRUNKDIR):..:$(C_INCLUDE_PATH)
test : LIBRARY_PATH=$(%LIBRARY_PATH)
test : code-page-db
test :  
	cd ../tests && EUDIR=$(TRUNKDIR) EUCOMPILEDIR=$(TRUNKDIR) $(EXE) ../source/eutest.ex -i ../include -cc gcc -exe $(BUILDDIR)/$(EEXU) -ec $(BUILDDIR)/$(EECU) -lib $(BUILDDIR)/$(EECUA)
	cd ../tests && sh check_diffs.sh

testeu : code-page-db
	cd ../tests && EUDIR=$(TRUNKDIR) EUCOMPILEDIR=$(TRUNKDIR) $(EXE) ../source/eutest.ex -i ../include -cc gcc -exe "$(BUILDDIR)/$(EEXU) -batch $(TRUNKDIR)/source/eu.ex"

ifeq "$(PREFIX)" ""
PREFIX=/usr/local
endif

install :
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar/Linux
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/tutorial 
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/bin 
	mkdir -p $(DESTDIR)/etc/euphoria 
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/source 
	mkdir -p $(DESTDIR)$(PREFIX)/bin 
	mkdir -p $(DESTDIR)$(PREFIX)/lib
	mkdir -p $(DESTDIR)$(PREFIX)/include/euphoria
	install $(BUILDDIR)/$(EECUA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EEXU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EECU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EBACKENDU) $(DESTDIR)$(PREFIX)/bin
	install ../include/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include
	install ../include/std/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std
	install ../include/std/net/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	install ../include/std/unix/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/unix
	install ../include/std/win32/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	install ../include/euphoria/*  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	install ../include/euphoria.h $(DESTDIR)$(PREFIX)/share/euphoria/include
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/demo ../demo/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench ../demo/bench/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar ../demo/langwar/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar/Linux ../demo/langwar/Linux/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix ../demo/unix/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/tutorial ../tutorial/*
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/bin \
	           ../bin/ed.ex \
	           ../bin/ascii.ex \
	           ../bin/bugreport.ex \
	           ../bin/buildcpdb.ex \
	           $(BUILDDIR)/ecp.dat \
	           ../bin/eprint.ex \
	           ../bin/guru.ex \
	           ../bin/key.ex \
	           ../bin/lines.ex \
	           ../bin/search.ex \
	           ../bin/where.ex
	-install -t $(DESTDIR)$(PREFIX)/share/euphoria/source \
	           *.ex \
	           *.e \
	           be_*.c \
	           *.h
	# helper script for running dis.ex
	echo "#!/bin/sh" > $(DESTDIR)$(PREFIX)/bin/eudis
	echo eui $(PREFIX)/share/euphoria/source/dis.ex $$\@ >> $(DESTDIR)$(PREFIX)/bin/eudis
	chmod +x $(DESTDIR)$(PREFIX)/bin/eudis
	# helper script for binding programs
	echo "#!/bin/sh" > $(DESTDIR)$(PREFIX)/bin/eubind
	echo eui $(PREFIX)/share/euphoria/source/bind.ex $$\@ >> $(DESTDIR)$(PREFIX)/bin/eubind
	chmod +x $(DESTDIR)$(PREFIX)/bin/eubind
	# helper script for shrouding programs
	echo "#!/bin/sh" > $(DESTDIR)$(PREFIX)/bin/eushroud
	echo eui $(PREFIX)/share/euphoria/source/bind.ex -shroud_only $$\@ >> $(DESTDIR)$(PREFIX)/bin/eushroud
	chmod +x $(DESTDIR)$(PREFIX)/bin/eushroud

install-docs :
	# create dirs
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install $(BUILDDIR)/euphoria-4.0.pdf $(DESTDIR)$(PREFIX)/share/doc/euphoria/
	install -t $(DESTDIR)$(PREFIX)/share/doc/euphoria/html \
		$(BUILDDIR)/html/*html \
		$(BUILDDIR)/html/*css
	install -t $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images \
		$(BUILDDIR)/html/images/*
	install -t $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js \
		$(BUILDDIR)/html/js/*

# This doesn't seem right. What about eub or shroud ?
uninstall :
	-rm $(PREFIX)/bin/$(EEXU) $(PREFIX)/bin/$(EECU) $(PREFIX)/lib/$(EECUA) $(PREFIX)/lib/$(EBACKENDU)
	-rm -r $(PREFIX)/share/euphoria

uninstall-docs :
	-rm -rf $(PREFIX)/share/doc/euphoria

.PHONY : install install-docs
.PHONY : uninstall uninstall-docs

ifeq "$(EUPHORIA)" "1"
$(BUILDDIR)/intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(BUILDDIR)/transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(BUILDDIR)/backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)
endif

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@
	
$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o


ifeq "$(EUPHORIA)" "1"

$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN)
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	cp Makefile Makefile.gnu $(CONFIG) revget.ex $(BUILDDIR)/$(OBJDIR)
	rm -f $(BUILDDIR)/$(OBJDIR)/{*.c,*.o}
	(cd $(BUILDDIR)/$(OBJDIR);$(TRANSLATE) -nobuild $(INCDIR) -$(XLTTARGETCC) $(RELEASE_FLAG) $(TARGETPLAT)  $(TRUNKDIR)/source/$(EU_TARGET) )
	
endif

$(BUILDDIR)/$(OBJDIR)/back/%.o : %.c execute.h alloc.h global.h alldefs.h opnames.h reswords.h symtab.h Makefile.eu
	$(CC) $(BE_FLAGS) $(EBSDFLAG) $*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : ./$(BE_CALLC).c Makefile.eu
	$(CC) -c -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.o
	$(CC) -S -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.s

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : ./be_inline.c Makefile.eu
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$*.o
	
ifdef PCRE_OBJECTS	
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,pcre/%.c,$(PCRE_OBJECTS)) pcre/config.h.unix pcre/pcre.h.unix
	$(MAKE) -C pcre all CC="$(PCRE_CC)" PCRE_CC="$(PCRE_CC)" EOSTYPE="$(EOSTYPE)" CONFIG=../$(CONFIG)
endif
