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

include Makefile.$(OBJDIR)smak

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
	EECU=ec
	EEXU=ex
	EECUA=ec.a
	MEM_FLAGS=
	ECHO=echo
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
	shift.e

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


Makefile.$(OBJDIR)smak :
	$(ECHO) "#" > $@

BUILD_DIRS=intobj/back transobj/back libobj/back backobj/back intobj/ transobj/ libobj/ backobj/

distclean : clean
	-rm rev.e
	-rm -r $(BUILD_DIRS)

clean : 
	@-for d in $(BUILD_DIRS); \
	do \
	    rm "$$d"/*.o ; rm "$$d"/*.c; \
	done
	-rm $(EEXU) $(EECU) $(EECUA) $(EBACKENDU) $(DEB_SOURCE_DIR).tar.gz

.PHONY : clean distclean all

library : builddirs
	$(MAKE) $(EECUA) OBJDIR=libobj ERUNTIME=1
$(EECUA) : $(EU_LIB_OBJECTS)
	ar -rc $(EECUA) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)

builddirs : svn_rev
	@-for d in $(BUILD_DIRS); \
	do \
		mkdir -p "$$d"; \
	done

svn_rev : 
	-$(EXE) -i ../include revget.ex ../.svn/entries

interpreter : builddirs
	$(MAKE) exusource OBJDIR=intobj EBSD=$(EBSD)
	$(MAKE) $(EEXU) OBJDIR=intobj EBSD=$(EBSD)

translator : builddirs
	$(MAKE) ecusource OBJDIR=transobj EBSD=$(EBSD)
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
	cp Makefile    $(SOURCEDIR)
	cp Makefile.*s $(SOURCEDIR)
	cp configure   $(SOURCEDIR)
	cp ../include/euphoria.h $(SOURCEDIR)
	cp *.h         $(SOURCEDIR)
	
.PHONY : exusource
.PHONY : ecusource
.PHONY : backendsource
.PHONY : source

$(EEXU) :  EU_TARGET = int.ex
$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
$(EEXU) :  EU_OBJS = $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EEXU)
	if [ "$(EMINGW)" = "1" ]; then $(CC) $(EOSFLAGSCONSOLE) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EEXUC); fi

$(EECU) :  OBJDIR = transobj
$(EECU) :  EU_TARGET = ec.ex
$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EECU) : $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EECU)

backend : builddirs
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj
	$(MAKE) $(EBACKENDU) EBACKEND=1 OBJDIR=backobj

$(EBACKENDU) : OBJDIR = backobj
$(EBACKENDU) : EU_TARGET = backend.ex
$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(EBACKENDU) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@$(ECHO) making BACKENDU $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EBACKENDU)
	if [ "$(EMINGW)" = "1" ]; then $(CC) $(EOSFLAGSCONSOLE) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -o $(EBACKENDC); fi

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
intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@
	
./$(OBJDIR)/%.o : ./$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) ./$(OBJDIR)/$*.c -I/usr/share/euphoria -o./$(OBJDIR)/$*.o

./$(OBJDIR)/%.c : $(EU_MAIN) 
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	@-rm ./$(OBJDIR)/*.c
	cd ./$(OBJDIR) && $(EXE) $(INCDIR) ../ec.ex $(RELEASE_FLAG) $(INCDIR) $(TARGETPLAT) ../$(EU_TARGET)
	@cd ./$(OBJDIR) && \
	if [ "$(OBJDIR)" = "backobj" ]; then \
		$(ECHO) -e "EU_BACKEND_RUNNER_OBJECTS = \\" > ../Makefile.$(OBJDIR)smak ; \
	elif [ "$(OBJDIR)" = "transobj" ]; then \
		$(ECHO) -e "EU_TRANSLATOR_OBJECTS = \\" > ../Makefile.$(OBJDIR)smak ; \
	elif [ "$(OBJDIR)" = "intobj" ]; then \
		$(ECHO) -e "EU_INTERPRETER_OBJECTS = \\" > ../Makefile.$(OBJDIR)smak ; \
	fi && \
	for i in *.c; \
	do \
		$(ECHO) -e "./$(OBJDIR)/`basename $$i .c`.o \\" >> ../Makefile.$(OBJDIR)smak ; \
	done && \
	$(ECHO) -ne "\t" >> ../Makefile.$(OBJDIR)


./$(OBJDIR)/back/%.o : %.c
	$(CC) $(BE_FLAGS) $(EBSDFLAG) $*.c -o./$(OBJDIR)/back/$*.o

$(OBJDIR)/back/be_callc.o : ./be_callc.c
	$(CC) -c -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) -fsigned-char -Os -O3 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(OBJDIR)/back/be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$*.o
