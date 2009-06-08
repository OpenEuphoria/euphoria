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
#  Configue options:
#
#     --without-euphoria      Use this option if you are building Euphoria 
#		     with only a C compiler.
# 
#     --eubin <dir>   Use this option to speuify the location of the interpreter
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
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean
#        translated files
#   Everything                :  make
#   Interpreter          (eui):  make interpreter
#   Translator           (euc):  make translator
#   Translator Library (eu.a):  make library
#   Backend              (eub):  make eub
#   Run Unit Tests            :  make test
#   Run Unit Tests for DJGPP  :  make test-djgpp
#   Run Unit Tests with eu.ex :  make testeu

ifndef CONFIG
CONFIG = Makefile.eu
endif

include $(CONFIG)
include $(TRUNKDIR)/source/pcre/objects.mak
include $(TRUNKDIR)/source/version.mak

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
	EECUA=ecw.a
	ifeq "$(MANAGED_MEM)" "1"
		MEM_FLAGS=
	else
		MEM_FLAGS=-DESIMPLE_MALLOC
	endif
else
ifeq "$(EDJGPP)" "1"
	EOSTYPE=-DEDOS -DEDJGPP
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSMING=-O2
	EBACKENDU=eubd.exe
	EBACKENDC=eubd.exe
	EECU=euc.exe
	EEXU=eui.exe
	EECUA=eud.a
	PLAT=DOS
	MEM_FLAGS=
	LDLFLAG=-lalleg
	ECHO=echo
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
endif

ifdef EDEBUG
DEBUG_FLAGS=-g3 -O0 -Wall
CALLC_DEBUG=-g3
EC_DEBUG=-D DEBUG
else
DEBUG_FLAGS=-fomit-frame-pointer $(EOSMING)
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

ifndef ECHO
ECHO=/bin/echo
endif

CC = gcc
FE_FLAGS =  -c -w -fsigned-char $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/
BE_FLAGS =  -c -w $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(DEBUG_FLAGS) $(MEM_FLAGS)

EU_CORE_FILES = \
	common.e \
	main.e \
	mode.e \
	pathopen.e \
	platform.e \
	error.e \
	symtab.e \
	scanner.e \
	scinot.e \
	emit.e \
	parser.e \
	opnames.e \
	reswords.e \
	keylist.e \
	fwdref.e \
	shift.e \
	inline.e \
	block.e

EU_INTERPRETER_FILES = \
	global.e \
	compress.e \
	backend.e \
	c_out.e \
	cominit.e \
	intinit.e \
	int.ex

EU_TRANSLATOR_FILES = \
	buildsys.e \
	c_decl.e \
	c_out.e \
	cominit.e \
	compile.e \
	compress.e \
	ec.ex \
	global.e \
	traninit.e

EU_BACKEND_RUNNER_FILES = \
	intinit.e \
	cominit.e \
	backend.e \
	pathopen.e \
	backend.ex \
	compress.e \
	backend.e \
	error.e \
	mode.e

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
	

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all : interpreter translator library backend

version.h: version.mak
	echo // DO NOT EDIT, EDIT version.mak INSTEAD > version.h
	echo \#define MAJ_VER $(MAJ_VER) >> version.h
	echo \#define MAJ_VER $(MAJ_VER) > version.h
	echo \#define MIN_VER $(MIN_VER) >> version.h
	echo \#define PAT_VER $(PAT_VER) >> version.h
	echo \#define REL_TYPE \"$(REL_TYPE)\" >> version.h

BUILD_DIRS=$(BUILDDIR)/intobj/back $(BUILDDIR)/transobj/back $(BUILDDIR)/libobj/back $(BUILDDIR)/backobj/back $(BUILDDIR)/intobj/ $(BUILDDIR)/transobj/ $(BUILDDIR)/libobj/ $(BUILDDIR)/backobj/

distclean : clean
	-rm -f $(CONFIG)
	-rm -fr $(BUILD_DIRS)

clean : 	
	-rm -fr $(BUILDDIR)/intobj
	-rm -fr $(BUILDDIR)/transobj
	-rm -fr $(BUILDDIR)/libobj
	-rm -fr $(BUILDDIR)/backobj
	-rm -f $(BUILDDIR)/$(EEXU) $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA) $(BUILDDIR)/$(EBACKENDU) $(BUILDDIR)/$(DEB_SOURCE_DIR).tar.gz
ifeq "$(MINGW)" "1"
	-rm -f $(BUILDDIR)/{$(EBACKENDC),$(EEXUW)}
endif
	-rm -f version.h
	$(MAKE) -C pcre CONFIG=../$(CONFIG) clean
	

.PHONY : clean distclean all

library : version.h builddirs
	$(MAKE) $(BUILDDIR)/$(EECUA) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG)
$(BUILDDIR)/$(EECUA) : $(EU_LIB_OBJECTS)
	ar -rc $(BUILDDIR)/$(EECUA) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)

builddirs : svn_rev
	mkdir -p $(BUILD_DIRS) 

svn_rev : 
	-$(EXE) -i ../include revget.ex -svnentries ../.svn/entries

interpreter : version.h builddirs
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG)
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG)

translator : version.h builddirs
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG)
	$(MAKE) $(BUILDDIR)/$(EECU) OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG)

.PHONY : library
.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev

euisource : $(BUILDDIR)/intobj/main-.c
euisource :  EU_TARGET = int.ex
eucsource : $(BUILDDIR)/transobj/main-.c
eucsource :  EU_TARGET = ec.ex
backendsource : $(BUILDDIR)/backobj/main-.c
backendsource :  EU_TARGET = backend.ex
source : builddirs
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG)

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
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXU)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EEXU)
endif
	
$(BUILDDIR)/$(EECU) :  OBJDIR = transobj
$(BUILDDIR)/$(EECU) :  EU_TARGET = ec.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(BUILDDIR)/$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EECU) : $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EECU)

backend : version.h builddirs
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)
	$(MAKE) $(BUILDDIR)/$(EBACKENDU) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)

$(BUILDDIR)/$(EBACKENDU) : OBJDIR = backobj
$(BUILDDIR)/$(EBACKENDU) : EU_TARGET = backend.ex
$(BUILDDIR)/$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(BUILDDIR)/$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EBACKENDU) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making BACKENDU $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EBACKENDU)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(BUILDDIR)/$(EBACKENDC)
endif


test :  
ifeq "$(EDJGPP)" "1"
ifneq "$(HASCHANGEDDIRECTORY)" "1"
	cp $(CONFIG) revget.ex ../tests
	export EUCOMPILEDIR=$(TRUNKDIR)
	$(MAKE) -k -C ../tests -f ../source/Makefile EUCOMPILEDIR=.. CONFIG=$(CONFIG) HASCHANGEDDIRECTORY=1 test   
else
	$(EXE) $(TRUNKDIR)/source/eutest.ex -i $(TRUNKDIR)/include -cc gcc -exe $(BUILDDIR)/$(EEXU) -ec $(BUILDDIR)/$(EECU) -lib $(BUILDDIR)/$(EECUA)
endif
else # Not DJGPP:
	cd ../tests && EUDIR=$(TRUNKDIR) EUCOMPILEDIR=$(TRUNKDIR) $(EXE) ../source/eutest.ex -i ../include -cc gcc -exe $(BUILDDIR)/$(EEXU) -ec $(BUILDDIR)/$(EECU) -lib $(BUILDDIR)/$(EECUA)
endif

testeu :
	cd ../tests && EUDIR=$(TRUNKDIR) EUCOMPILEDIR=$(TRUNKDIR) $(EXE) ../source/eutest.ex -i ../include -cc gcc -exe "$(BUILDDIR)/$(EEXU) $(TRUNKDIR)/source/eu.ex"

install :
	mkdir -p $(DESTDIR)/usr/share/euphoria/include/euphoria
	mkdir -p $(DESTDIR)/usr/share/euphoria/include/std/net/dos
	mkdir -p $(DESTDIR)/usr/share/euphoria/include/std/dos
	mkdir -p $(DESTDIR)/usr/share/doc/euphoria/html 
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/unix
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/net
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/win32
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/dos
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/bench
	mkdir -p $(DESTDIR)/usr/share/doc/euphoria/doc
	mkdir -p $(DESTDIR)/usr/share/euphoria/tutorial 
	mkdir -p $(DESTDIR)/usr/share/euphoria/bin 
	mkdir -p $(DESTDIR)/etc/euphoria 
	mkdir -p $(DESTDIR)/usr/share/euphoria/source 
	mkdir -p $(DESTDIR)/usr/bin 
	mkdir -p $(DESTDIR)/usr/lib
	mkdir -p $(DESTDIR)/usr/include/euphoria
	install $(EECUA) $(DESTDIR)/usr/lib
	install eui $(DESTDIR)/usr/bin
	install euc $(DESTDIR)/usr/bin
	install eu.a $(DESTDIR)/usr/lib
	install ../include/*e  $(DESTDIR)/usr/share/euphoria/include
	install ../include/std/*e  $(DESTDIR)/usr/share/euphoria/include/std
	install ../include/std/net/*e  $(DESTDIR)/usr/share/euphoria/include/std/net
	install ../include/std/unix/*e  $(DESTDIR)/usr/share/euphoria/include/std/unix
	install ../include/std/win32/*e  $(DESTDIR)/usr/share/euphoria/include/std/win32
	install ../include/std/dos/*e  $(DESTDIR)/usr/share/euphoria/include/std/dos
	install ../include/euphoria/*  $(DESTDIR)/usr/share/euphoria/include/euphoria
	install ../include/euphoria.h $(DESTDIR)/usr/share/euphoria/include
	-install -t $(DESTDIR)/usr/share/doc/euphoria/html ../html/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo ../demo/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/bench ../demo/bench/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar ../demo/langwar/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux ../demo/langwar/Linux/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/unix ../demo/unix/*
	-install -t $(DESTDIR)/usr/share/euphoria/tutorial ../tutorial/*
	install -t $(DESTDIR)/usr/share/euphoria/bin \
	           ../bin/ed.ex \
	           ../bin/ascii.ex \
	           ../bin/eprint.ex \
	           ../bin/guru.ex \
	           ../bin/key.ex \
	           ../bin/lines.ex \
	           ../bin/search.ex \
	           ../bin/where.ex
	-install -t $(DESTDIR)/usr/share/euphoria/source \
	           *.ex \
	           *.e \
	           be_*.c \
	           *.h

# This doesn't seem right. What about eub or eushroud ?
uninstall :
	-rm /usr/bin/$(EEXU) /usr/bin/$(EECU) /usr/lib/$(EECUA)
	-rm -r /usr/share/euphoria
	-rm -r /usr/share/doc/euphoria
	-rm -r /etc/euphoria

.PHONY : install
.PHONY : uninstall
$(BUILDDIR)/intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(BUILDDIR)/transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(BUILDDIR)/backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@
	
$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o

ifneq	"$(HASCHANGEDDIRECTORY)" "1"
$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN)
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	cp Makefile Makefile.gnu $(CONFIG) revget.ex $(BUILDDIR)/$(OBJDIR)
	rm -f $(BUILDDIR)/$(OBJDIR)/{*.c,*.o}
	$(MAKE) translate-here -k -C $(BUILDDIR)/$(OBJDIR) EU_TARGET=$(EU_TARGET) SHELL=$(SHELL) CONFIG=$(CONFIG) HASCHANGEDDIRECTORY=1 
endif

ifeq "$(HASCHANGEDDIRECTORY)" "1"
translate-here :
	$(EXE) $(TRUNKDIR)/source/ec.ex -nobuild $(INCDIR) -gcc $(EC_DEBUG) $(RELEASE_FLAG) $(TARGETPLAT) $(TRUNKDIR)/source/$(EU_TARGET)

.PHONY : translate-here
	
endif	

$(BUILDDIR)/$(OBJDIR)/back/%.o : %.c execute.h alloc.h global.h alldefs.h opnames.h reswords.h symtab.h Makefile.eu
	$(CC) $(BE_FLAGS) $(EBSDFLAG) $*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : ./be_callc.c Makefile.eu
	$(CC) -c -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : ./be_inline.c Makefile.eu
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$*.o
	
ifdef PCRE_OBJECTS	
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,pcre/%.c,$(PCRE_OBJECTS)) pcre/config.h.unix pcre/pcre.h.unix
	$(MAKE) -C pcre all EOSTYPE=$(EOSTYPE) CONFIG=../$(CONFIG)
endif
