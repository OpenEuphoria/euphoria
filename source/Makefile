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
	EOSMING=-ffast-math -O3 -Os
	EBACKENDU=backendw
	EBACKENDC=backendc
	EECU=ecw
	EEXU=exw
	EECUA=ecw.a
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

ifeq "$(EU3)" "1"
EXE=export EUINC=$(PWD)/../include && $(EEXU)
INCDIR=
else
EXE=$(EEXU)
INCDIR=-i ../../include
endif

ifdef PLAT
TARGETPLAT=-plat $(PLAT)
endif

CC = gcc
FE_FLAGS =  -c -w -fsigned-char $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/
BE_FLAGS =  -c -w $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -I./pcre/ -fsigned-char -ffast-math $(DEBUG_FLAGS) -DESIMPLE_MALLOC

PCRE=./pcre/.libs/libpcre.a

EU_CORE_FILES = \
	common.e \
	main.e \
	mode.e \
	pathopen.e \
	error.e \
	symtab.e \
	scanner.e \
	scientific.e \
	emit.e \
	parser.e \
	opnames.e \
	reswords.e \
	keylist.e

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

EU_TRANSLATOR_OBJECTS = \
	./$(OBJDIR)/ec.o \
	./$(OBJDIR)/c_decl.o \
	./$(OBJDIR)/c_dec0.o \
	./$(OBJDIR)/c_dec1.o \
	./$(OBJDIR)/compile.o \
	./$(OBJDIR)/compil_0.o \
	./$(OBJDIR)/compil_1.o \
	./$(OBJDIR)/compil_2.o \
	./$(OBJDIR)/compil_3.o \
	./$(OBJDIR)/compil_4.o \
	./$(OBJDIR)/compil_5.o \
	./$(OBJDIR)/compil_6.o \
	./$(OBJDIR)/compil_7.o \
	./$(OBJDIR)/compil_8.o \
	./$(OBJDIR)/compil_9.o \
	./$(OBJDIR)/compil_A.o \
	./$(OBJDIR)/compress.o \
	./$(OBJDIR)/get.o \
	./$(OBJDIR)/0rror.o \
	./$(OBJDIR)/global.o \
	./$(OBJDIR)/sort.o \
	./$(OBJDIR)/sequence.o \
	./$(OBJDIR)/text.o \
	./$(OBJDIR)/wildcard.o \
	./$(OBJDIR)/traninit.o \
	./$(OBJDIR)/tranplat.o \
	./$(OBJDIR)/types.o \
	./$(OBJDIR)/dll.o \
	./$(OBJDIR)/filesys.o \
	./$(OBJDIR)/io.o \
	./$(OBJDIR)/search.o
	
EU_INTERPRETER_OBJECTS =  \
	./$(OBJDIR)/backend.o \
	./$(OBJDIR)/intinit.o \
	./$(OBJDIR)/tranplat.o \
	./$(OBJDIR)/dll.o \
	./$(OBJDIR)/sequence.o \
	./$(OBJDIR)/text.o \
	./$(OBJDIR)/wildcard.o \
	./$(OBJDIR)/get.o \
	./$(OBJDIR)/sort.o \
	./$(OBJDIR)/types.o \
	./$(OBJDIR)/compress.o \
	./$(OBJDIR)/filesys.o \
	./$(OBJDIR)/search.o

EU_CORE_OBJECTS = \
	./$(OBJDIR)/main-.o \
	./$(OBJDIR)/main-0.o \
	./$(OBJDIR)/convert.o \
	./$(OBJDIR)/cominit.o \
	./$(OBJDIR)/pathopen.o \
	./$(OBJDIR)/init-.o \
	./$(OBJDIR)/error.o \
	./$(OBJDIR)/memory.o \
	./$(OBJDIR)/mode.o \
	./$(OBJDIR)/c_out.o \
	./$(OBJDIR)/symtab.o \
	./$(OBJDIR)/symtab_0.o \
	./$(OBJDIR)/scanner.o \
	./$(OBJDIR)/scientific.o \
	./$(OBJDIR)/scanne_0.o \
	./$(OBJDIR)/main.o \
	./$(OBJDIR)/emit.o \
	./$(OBJDIR)/emit_0.o \
	./$(OBJDIR)/emit_1.o \
	./$(OBJDIR)/parser.o \
	./$(OBJDIR)/parser_0.o \
	./$(OBJDIR)/parser_1.o \
	./$(OBJDIR)/parser_2.o \
	./$(OBJDIR)/parser_3.o

EU_CORE_C_FILES = \
	./$(OBJDIR)/main-.c \
	./$(OBJDIR)/main-0.c \
	./$(OBJDIR)/pathopen.c \
	./$(OBJDIR)/init-.c \
	./$(OBJDIR)/io.c \
	./$(OBJDIR)/error.c \
	./$(OBJDIR)/machine.c \
	./$(OBJDIR)/symtab.c \
	./$(OBJDIR)/symtab_0.o \
	./$(OBJDIR)/scanner.c \
	./$(OBJDIR)/scanne_0.c \
	./$(OBJDIR)/scientific.o \
	./$(OBJDIR)/main.c \
	./$(OBJDIR)/mode.c \
	./$(OBJDIR)/emit.c \
	./$(OBJDIR)/emit_0.c \
	./$(OBJDIR)/emit_1.c \
	./$(OBJDIR)/parser.c \
	./$(OBJDIR)/parser_0.c \
	./$(OBJDIR)/parser_1.c \
	./$(OBJDIR)/parser_2.c \
	./$(OBJDIR)/parser_3.c
	
EU_BACKEND_OBJECTS = \
	./$(OBJDIR)/back/be_decompress.o \
	./$(OBJDIR)/back/be_execute.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_main.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_callc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_pcre.o \
	./$(OBJDIR)/back/be_rterror.o \
	./$(OBJDIR)/back/be_syncolor.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_symtab.o \
	./$(OBJDIR)/back/be_w.o

EU_LIB_OBJECTS = \
	./$(OBJDIR)/back/be_decompress.o \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_w.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_pcre.o \
	./$(OBJDIR)/back/be_callc.o

EU_BACKEND_RUNNER_OBJECTS = \
	./$(OBJDIR)/main-.o \
	./$(OBJDIR)/init-.o \
	./$(OBJDIR)/intinit.o \
	./$(OBJDIR)/cominit.o \
	./$(OBJDIR)/io.o \
	./$(OBJDIR)/memory.o \
	./$(OBJDIR)/0ackend.o \
	./$(OBJDIR)/pathopen.o \
	./$(OBJDIR)/backend.o \
	./$(OBJDIR)/compress.o \
	./$(OBJDIR)/error.o \
	./$(OBJDIR)/text.o \
	./$(OBJDIR)/sort.o \
	./$(OBJDIR)/mode.o \
	./$(OBJDIR)/types.o \
	./$(OBJDIR)/dll.o \
	./$(OBJDIR)/convert.o \
	./$(OBJDIR)/filesys.o \
	./$(OBJDIR)/get.o \
	./$(OBJDIR)/wildcard.o \
	./$(OBJDIR)/search.o

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

PCRE_OBJECTS = \
	./pcre/*.o
all : interpreter translator library backend

BUILD_DIRS=intobj/back transobj/back libobj/back backobj/back intobj/ transobj/ libobj/ backobj/

distclean : clean
	-rm rev.e
	-rm -r $(BUILD_DIRS)
	cd pcre && $(MAKE) clean

clean : 
	@-for d in $(BUILD_DIRS); \
	do \
	    rm "$$d"/*.o; \
	done
	-rm $(EEXU) $(EECU) $(EECUA) $(EBACKENDU) $(DEB_SOURCE_DIR).tar.gz
	cd pcre && $(MAKE) clean

.PHONY : clean distclean all

library : builddirs $(PCRE)
	$(MAKE) $(EECUA) OBJDIR=libobj ERUNTIME=1
$(EECUA) : $(EU_LIB_OBJECTS)
	ar -rc $(EECUA) $(PCRE_OBJECTS) $(EU_LIB_OBJECTS)
	echo $(MAKEARGS)

builddirs : svn_rev
	@-for d in $(BUILD_DIRS); \
	do \
		mkdir -p "$$d"; \
	done

svn_rev : 
	-$(EXE) -i ../include revget.ex .svn/entries

interpreter : builddirs $(PCRE)
	$(MAKE) $(EEXU) OBJDIR=intobj EBSD=$(EBSD)

translator : builddirs $(PCRE)
	$(MAKE) $(EECU) OBJDIR=transobj EBSD=$(EBSD)

.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev

exusource : intobj/main-.c
exusource :  EU_TARGET = int.ex
ecusource : transobj/main-.c
ecusource :  EU_TARGET = ec.ex
backendsource : backobj/main-.c
backendsource :  EU_TARGET = backend.ex
source : builddirs
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
	cp -r pcre     $(SOURCEDIR)
	cp Makefile    $(SOURCEDIR)
	cp configure   $(SOURCEDIR)
	cp ../include/euphoria.h $(SOURCEDIR)
	cp *.h         $(SOURCEDIR)
	
.PHONY : exusource
.PHONY : ecusource
.PHONY : backendsource
.PHONY : source

$(EEXU) :  EU_TARGET = int.ex
$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(EEXU) :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EEXU) :  $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making $(EEXU)
	@echo $(OS)
	$(CC) $(EOSFLAGS) $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(PCRE) $(LDLFLAG) -o $(EEXU)
	if [ "$(EMINGW)" = "1" ]; then $(CC) $(EOSFLAGSCONSOLE) $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(PCRE) $(LDLFLAG) -o $(EEXU)c; fi

$(EECU) :  OBJDIR = transobj
$(EECU) :  EU_TARGET = ec.ex
$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(EECU) :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EECU) : $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(PCRE) $(LDLFLAG) -o $(EECU)

backend : builddirs
	$(MAKE) $(EBACKENDU) EBACKEND=1 OBJDIR=backobj

$(EBACKENDU) : OBJDIR = backobj
$(EBACKENDU) : EU_TARGET = backend.ex
$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EBACKENDU) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making BACKENDU $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PCRE) -lm $(LDLFLAG) -o $(EBACKENDU)
	if [ "$(EMINGW)" = "1" ]; then $(CC) $(EOSFLAGSCONSOLE) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PCRE) -lm $(LDLFLAG) -o $(EBACKENDC); fi

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
	install $(EEXU) $(EECU) $(EBACKENDU) eubind eushroud $(DESTDIR)/usr/bin
	install $(EECUA) $(DESTDIR)/usr/lib
	install ../include/*e  $(DESTDIR)/usr/share/euphoria/include
	install ../include/std/*e  $(DESTDIR)/usr/share/euphoria/include/std
	install ../include/euphoria/*  $(DESTDIR)/usr/share/euphoria/include/euphoria
	install ../include/euphoria.h $(DESTDIR)/usr/share/euphoria/include
	install -t $(DESTDIR)/usr/share/doc/euphoria/html ../html/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo ../demo/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/bench ../demo/bench/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar ../demo/langwar/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux ../demo/langwar/Linux/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/unix ../demo/unix/*
	install -t $(DESTDIR)/usr/share/doc/euphoria/doc ../doc/*
	install -t $(DESTDIR)/usr/share/euphoria/tutorial ../tutorial/*
	install -t $(DESTDIR)/usr/share/euphoria/bin \
	           ../bin/ed.ex \
	           ../bin/ascii.ex \
	           ../bin/eprint.ex \
	           ../bin/guru.ex \
	           ../bin/key.ex \
	           ../bin/lines.ex \
	           ../bin/search.ex \
	           ../bin/where.ex
	install -t $(DESTDIR)/usr/share/euphoria/source \
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
intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
transobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@
	
./$(OBJDIR)/%.o : ./$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) ./$(OBJDIR)/$*.c -I/usr/share/euphoria -o./$(OBJDIR)/$*.o

#./$(OBJDIR)/main-.c : $(EU_MAIN)
#	echo Translating $(EU_TARGET) to create $(EU_MAIN)
#	cd ./$(OBJDIR) && exu ../ec.ex ../$(EU_TARGET)

#./$(OBJDIR)/main-.c
./$(OBJDIR)/%.c : $(EU_MAIN) 
	echo Translating $(EU_TARGET) to create $(EU_MAIN)
	-cd ./$(OBJDIR) && $(EXE) $(INCDIR) ../ec.ex $(INCDIR) $(TARGETPLAT) ../$(EU_TARGET)

./$(OBJDIR)/back/%.o : %.c
	$(CC) $(BE_FLAGS) $(EBSDFLAG) $*.c -o./$(OBJDIR)/back/$*.o

$(OBJDIR)/back/be_callc.o : ./be_callc.c
	$(CC) -c -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(OBJDIR)/back/be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$*.o

$(PCRE) : 
	cd pcre && $(MAKE) libpcre.la
