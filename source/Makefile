# GNU Makefile for Euphoria (Linux and FreeBSD)
#
# NOTE: This is meant to be used with GNU make,
#       so on BSD, you should use gmake instead
#       of make
#
# Syntax:
#
#   Configure the make system :  ./configure
#   You must run configure
#   before building
#
#  Configue options:
#                    --with-eu3  If you have only a euphoria v3.x interpreter installed,
#                                put this option on the command line
#
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean
#        translated files
#   Everything                :  make
#   Interpreter          (exu):  make interpreter
#   Translator           (ecu):  make translator
#   Translator Library (ecu.a):  make library
#   Backend         (backendu):  make backendu
#   Run Unit Tests            :  make test

include Makefile.eu

EU_VERSION = 4.0

ifeq "$(RELEASE)" "1"
RELEASE_FLAG = -D EU_FULL_RELEASE
endif

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EBACKEND
BACKEND_FLAGS = -DBACKEND
endif

ifeq  "$(EBSD)" "1"
  LDLFLAG=
  EBSDFLAG=-DEBSD -DEBSD62
  SEDFLAG=-Ei
  ifeq "$(EOSX)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DEOSX
  endif
else
  LDLFLAG=-ldl
  PREREGEX=$(FROMBSDREGEX)
  SEDFLAG=-ri
endif

ifeq "$(EMINGW)" "1"
	EOSTYPE=-DEWINDOWS
	EBSDFLAG=-DEMINGW
	LDLFLAG=
	SEDFLAG=-ri
	EOSFLAGS=-mno-cygwin -mwindows
	EOSFLAGSCONSOLE=-mno-cygwin
	ifdef EDEBUG
		EOSMING=
	else
		EOSMING=-ffast-math -O3 -Os
	endif
	EBACKENDU=backendw.exe
	EBACKENDC=backendc.exe
	EECU=ecw.exe
	EEXU=exw.exe
	EEXUC=exwc.exe
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
	EBACKENDU=backendd
	EBACKENDC=backendd
	EECU=ec.exe
	EEXU=ex.exe
	EECUA=ec.a
	#malloc is not 8-byte aligned on djgpp's malloc
	MEM_FLAGS=
	LDLFLAG=-lalleg
	ECHO=echo
	PLAT=DOS
else
	EOSTYPE=-DEUNIX
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSMING=-O2
	EBACKENDU=backendu
	EBACKENDC=backendu
	EECU=ecu
	EEXU=exu
	EECUA=ecu.a
	MEM_FLAGS=-DESIMPLE_MALLOC
endif
endif



ifdef EDEBUG
DEBUG_FLAGS=-g3 -O0
CALLC_DEBUG=-g3
else
DEBUG_FLAGS=-fomit-frame-pointer $(EOSMING)
endif

ifeq  "$(ELINUX)" "1"
EBSDFLAG=-DELINUX
endif

EXE=$(EEXU)
INCDIR=-i ../../include

ifdef PLAT
TARGETPLAT=-plat $(PLAT)
endif

ifndef ECHO
ECHO=/bin/echo
endif

CC = gcc
FE_FLAGS =  -c -w -fsigned-char $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/
BE_FLAGS =  -c -w $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(DEBUG_FLAGS) $(MEM_FLAGS)

EU_INCLUDE_FILES = $(wildcard ..\include\std\*.e) $(wildcard ..\include\euphoria\*.e) 

EU_CORE_FILES = \
	common.e \
	main.e \
	mode.e \
	pathopen.e \
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
	rev.e

EU_INTERPRETER_FILES = \
	global.e \
	compress.e \
	backend.e \
	c_out.e \
	cominit.e \
	intinit.e \
	int.ex

EU_TRANSLATOR_FILES = \
	compile.e \
	compress.e \
	global.e \
	ec.ex \
	c_decl.e \
	c_out.e \
	global.e \
	cominit.e \
	traninit.e \
	tranplat.e

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

EU_BACKEND_OBJECTS = \
	./$(OBJDIR)/back/be_decompress.o \
	./$(OBJDIR)/back/be_execute.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_main.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_callc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_regex.o \
	./$(OBJDIR)/back/be_rterror.o \
	./$(OBJDIR)/back/be_syncolor.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_symtab.o \
	./$(OBJDIR)/back/be_w.o \
	./$(OBJDIR)/back/regex.o

EU_LIB_OBJECTS = \
	./$(OBJDIR)/back/be_decompress.o \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_w.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_regex.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_callc.o \
	./$(OBJDIR)/back/regex.o

all : interpreter translator library backend


BASE_BUILD_DIRS=intobj transobj libobj backobj
BACK_BUILD_DIRS=intobj/back transobj/back libobj/back backobj/back
BUILD_DIRS=$(BASE_BUILD_DIRS) $(BACK_BUILD_DIRS)

# Need to call mkdir with -p because gnu makes this target even
# when it exists (why?) and when it does
# the -p switch supresses already exists error.
$(BACK_BUILD_DIRS)  : %obj/back : %obj 
	mkdir -p $@
	
$(BASE_BUILD_DIRS)  : %obj : 
	mkdir -p $@
	
distclean : 
	-rm -fr rev.e
	-rm -fr $(BUILD_DIRS)
	-rm -f $(EEXU) $(EECU) $(EECUA) $(EBACKENDU) $(DEB_SOURCE_DIR).tar.gz

clean : 
	@-for d in $(BUILD_DIRS); \
	do \
	    rm -f "$$d"/*.o ;  \
	done
	-rm -f $(EEXU) $(EECU) $(EECUA) $(EBACKENDU) $(DEB_SOURCE_DIR).tar.gz

.PHONY : clean distclean all

library : $(BUILD_DIRS)
	$(MAKE) $(EECUA) OBJDIR=libobj ERUNTIME=1
$(EECUA) : $(EU_LIB_OBJECTS)
	ar -rc $(EECUA) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)

	
ifdef EUPHORIA
rev.e   :
	-$(EXE) -i ../include revget.ex ../.svn/entries
	
svn_rev : rev.e 
endif
interpreter : $(BUILD_DIRS)
	$(MAKE) EU_TARGET=int.ex OBJDIR=intobj EBSD=$(EBSD) int.ex.a
	$(MAKE) $(EEXU) EU_TARGET=int.ex OBJDIR=intobj EBSD=$(EBSD)

translator : $(BUILD_DIRS)
	$(MAKE) EU_TARGET=ec.ex OBJDIR=transobj EBSD=$(EBSD) ec.ex.a
	$(MAKE) $(EECU) EU_TARGET=ec.ex OBJDIR=transobj EBSD=$(EBSD)

.PHONY : $(BUILD_DIRS)
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev

exusource : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
	$(MAKE) EU_TARGET=int.ex OBJDIR=intobj EBSD=$(EBSD) ./intobj/main-.c

ecusource : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
	$(MAKE) EU_TARGET=ec.ex OBJDIR=transobj EBSD=$(EBSD) ./transobj/main-.c

backendsource : $(EU_CORE_FILES) $(EU_BACKEND_OBJECTS)
	$(MAKE) EU_TARGET=backend.ex OBJDIR=backobj EBSD=$(EBSD) ./backobj/main-.c


source : $(BUILD_DIRS)
	$(MAKE) exusource OBJDIR=intobj EBSD=$(EBSD)
	$(MAKE) ecusource OBJDIR=transobj EBSD=$(EBSD)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD)

SVN_REV=xxx
SOURCEDIR=euphoria-r$(SVN_REV)
source-tarball : source
	rm -rf $(SOURCEDIR)
	mkdir -p $(SOURCEDIR)
	cp -r intobj   $(SOURCEDIR)
	cp -r transobj $(SOURCEDIR)
	cp -r backobj  $(SOURCEDIR)
	cp -r libobj   $(SOURCEDIR)
	cp be_*.c      $(SOURCEDIR)
	cp int.ex      $(SOURCEDIR)
	cp ec.ex       $(SOURCEDIR)
	cp backend.ex  $(SOURCEDIR)
	cp *.e         $(SOURCEDIR)
	cp Makefile    $(SOURCEDIR)
	cp configure   $(SOURCEDIR)
	cp ../include/euphoria.h $(SOURCEDIR)
	cp *.h         $(SOURCEDIR)
	
.PHONY : exusource
.PHONY : ecusource
.PHONY : backendsource
.PHONY : source

ifdef EU_TARGET

$(EEXU) :  EU_TARGET = int.ex
$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(EEXU) :  EU_OBJS = $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EEXU) :  ./$(EU_TARGET).a $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
	$(CC) $(EOSFLAGS) ./$(EU_TARGET).a $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EEXU)
ifeq "$(EMINGW)"  "1" 
	$(CC) $(EOSFLAGSCONSOLE) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EEXUC)
endif

$(EECU) :  OBJDIR = transobj
$(EECU) :  EU_TARGET = ec.ex
$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EECU) : $(EU_TARGET).a $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) ./$(EU_TARGET).a $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EECU)

endif

backend : $(BUILD_DIRS)
	$(MAKE) EU_TARGET=backend.ex OBJDIR=backobj EBSD=$(EBSD) backend.ex.a
	$(MAKE) $(EBACKENDU) EU_TARGET=backend.ex OBJDIR=backobj EBSD=$(EBSD)
	
	
$(EBACKENDU) : OBJDIR = backobj
$(EBACKENDU) : EU_TARGET = backend.ex
$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EBACKENDU) : ./$(EU_TARGET).a $(EU_BACKEND_OBJECTS) Makefile
	@$(ECHO) making BACKENDU $(OBJDIR)
	ar r eu_backend.a $(EU_BACKEND_OBJECTS)
	$(CC) $(EOSFLAGS) $(EU_TARGET).a eu_backend.a -lm $(LDLFLAG) -o $(EBACKENDU)
# Don't use shell conditionals.  When they fail the target fails.	
ifeq "$(MINGW)" "1"
		$(CC) $(EOSFLAGSCONSOLE) $(EU_TARGET).a eu_backend.a -lm $(LDLFLAG) -o $(EBACKENDC);
endif

test : interpreter translator library
	export EUCOMPILEDIR=../ && \
	    cd ../tests/ && \
	     ../source/$(EEXU) -i ../include ../bin/eutest.ex -exe ../source/$(EEXU) -ec ../source/$(EECU) -lib ../source/$(EECUA)

install :
	mkdir -p $(DESTDIR)/usr/share/euphoria/include/euphoria
	mkdir -p $(DESTDIR)/usr/share/euphoria/include/std
	mkdir -p $(DESTDIR)/usr/share/doc/euphoria/html 
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/unix
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
	install exu $(DESTDIR)/usr/bin
	install ecu $(DESTDIR)/usr/bin
	install ecu.a $(DESTDIR)/usr/lib
	install ../include/*e  $(DESTDIR)/usr/share/euphoria/include
	install ../include/std/*e  $(DESTDIR)/usr/share/euphoria/include/std
	install ../include/euphoria/*  $(DESTDIR)/usr/share/euphoria/include/euphoria
	install ../include/euphoria.h $(DESTDIR)/usr/share/euphoria/include
	-install -t $(DESTDIR)/usr/share/doc/euphoria/html ../html/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo ../demo/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/bench ../demo/bench/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar ../demo/langwar/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux ../demo/langwar/Linux/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/unix ../demo/unix/*
	-install -t $(DESTDIR)/usr/share/doc/euphoria/doc ../doc/*
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

# This doesn't seem right. What about backendu or eushroud ?
uninstall :
	-rm /usr/bin/$(EEXU) /usr/bin/$(EECU) /usr/lib/$(EECUA)
	-rm -r /usr/share/euphoria
	-rm -r /usr/share/doc/euphoria
	-rm -r /etc/euphoria

.PHONY : install
.PHONY : uninstall

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@

ifdef EUPHORIA
./%obj/main-.c :
	@$(ECHO) Translating $(EU_TARGET)...
	@-rm ./$(OBJDIR)/*.c
	cd ./$(OBJDIR) && $(EXE) $(INCDIR) ../ec.ex $(RELEASE_FLAG) $(INCDIR) $(TARGETPLAT) ../$(EU_TARGET)	
endif

./intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDE_FILES)
./transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDE_FILES)
./backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDE_FILES)


./$(EU_TARGET).a :
ifdef EUPHORIA
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_TARGET).a
	@-rm ./$(OBJDIR)/*.c
	cd ./$(OBJDIR) && $(EXE) $(INCDIR) ../ec.ex $(RELEASE_FLAG) $(INCDIR) $(TARGETPLAT) ../$(EU_TARGET)
endif	
	@cd ./$(OBJDIR)
	cd ./$(OBJDIR) && for f in *.c; do echo $(EU_TARGET) $$f; $(CC) $(EBSDFLAG) $(FE_FLAGS) -I ../.. $$f -I/usr/share/euphoria ; done
	ar r $(EU_TARGET).a ./$(OBJDIR)/*.o

/int.ex.a : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDE_FILES) 
./ec.ex.a  : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDE_FILES) 
./backend.ex.a : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDE_FILES) 

./$(OBJDIR)/back/%.o : %.c
	$(CC) $(BE_FLAGS) $(EBSDFLAG) $*.c -o./$(OBJDIR)/back/$*.o

$(OBJDIR)/back/be_callc.o : ./be_callc.c
	$(CC) -c -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(OBJDIR)/back/be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$*.o
