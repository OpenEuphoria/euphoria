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
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean
#        translated files
#   Everything                :  make
#   Interpreter          (exu):  make interpreter
#   Translator           (ecu):  make translator
#   Translator Library (ecu.a):  make library
#   Backend         (backendu):  make backendu

include Makefile.eu
EU_VERSION = 3.2

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EBACKEND
BACKEND_FLAGS = -DBACKEND
endif

ifdef EDEBUG
DEBUG_FLAGS=-g3
CALLC_DEBUG=-g3
else
DEBUG_FLAGS=-fomit-frame-pointer
endif

ifeq  "$(EBSD)" "1"
LDLFLAG=
EBSDFLAG=-DEBSD -DEBSD62
SEDFLAG=-Ei
else
LDLFLAG=-ldl
PREREGEX=$(FROMBSDREGEX)
SEDFLAG=-ri
endif

CC = gcc
FE_FLAGS =  -c -w -fsigned-char -O2 -ffast-math $(DEBUG_FLAGS) -I../
BE_FLAGS =  -c -w -DELINUX $(EBSDFLAG) $(RUNTIME_FLAGS) $(BACKEND_FLAGS) -O2 -fsigned-char -ffast-math $(DEBUG_FLAGS) -DESIMPLE_MALLOC

EU_ALL_FILES = \
	be_alloc.c \
	be_callc.c \
	be_execute.c \
	be_inline.c \
	be_machine.c \
	be_main.c \
	be_rterror.c \
	be_runtime.c \
	be_symtab.c \
	be_syncolor.c \
	be_task.c \
	be_w.c \
	int.ex \
	ec.ex \
	backend.ex \
	bind.ex \
	backend.e \
	c_decl.e \
	cominit.e \
	common.e \
	compile.e \
	compress.e \
	c_out.e \
	emit.e \
	error.e \
	execute.e \
	global.e \
	il.e \
	intinit.e \
	keylist.e \
	main.e \
	mode.e \
	opnames.e \
	parser.e \
	pathopen.e \
	reswords.e \
	scanner.e \
	scientific.e \
	symtab.e \
	traninit.e \
	../include/machine.e \
	../include/wildcard.e \
	../include/misc.e \
	../include/file.e \
	../include/get.e


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
	global.e \
	ec.ex \
	c_decl.e \
	c_out.e \
	global.e \
	cominit.e \
	traninit.e

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
	./$(OBJDIR)/get.o \
	./$(OBJDIR)/global.o \
	./$(OBJDIR)/misc.o \
	./$(OBJDIR)/sort.o \
	./$(OBJDIR)/traninit.o \
	./$(OBJDIR)/wildcard.o

EU_INTERPRETER_OBJECTS =  \
	./$(OBJDIR)/backend.o \
	./$(OBJDIR)/intinit.o \
	./$(OBJDIR)/wildcard.o \
	./$(OBJDIR)/compress.o

EU_CORE_OBJECTS = \
	./$(OBJDIR)/main-.o \
	./$(OBJDIR)/main-0.o \
	./$(OBJDIR)/cominit.o \
	./$(OBJDIR)/pathopen.o \
	./$(OBJDIR)/init-.o \
	./$(OBJDIR)/file.o \
	./$(OBJDIR)/error.o \
	./$(OBJDIR)/machine.o \
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
	./$(OBJDIR)/parser_1.o 

EU_CORE_C_FILES = \
	./$(OBJDIR)/main-.c \
	./$(OBJDIR)/main-0.c \
	./$(OBJDIR)/pathopen.c \
	./$(OBJDIR)/init-.c \
	./$(OBJDIR)/file.c \
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
	./$(OBJDIR)/parser_1.c 
	
EU_BACKEND_OBJECTS = \
	./$(OBJDIR)/back/be_execute.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_main.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_callc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_rterror.o \
	./$(OBJDIR)/back/be_syncolor.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_symtab.o \
	./$(OBJDIR)/back/be_w.o

EU_LIB_OBJECTS = \
	./$(OBJDIR)/back/be_machine.o \
	./$(OBJDIR)/back/be_w.o \
	./$(OBJDIR)/back/be_alloc.o \
	./$(OBJDIR)/back/be_inline.o \
	./$(OBJDIR)/back/be_runtime.o \
	./$(OBJDIR)/back/be_task.o \
	./$(OBJDIR)/back/be_callc.o

EU_BACKEND_RUNNER_OBJECTS = \
	./$(OBJDIR)/main-.o \
	./$(OBJDIR)/init-.o \
	./$(OBJDIR)/intinit.o \
	./$(OBJDIR)/cominit.o \
	./$(OBJDIR)/file.o \
	./$(OBJDIR)/machine.o \
	./$(OBJDIR)/0ackend.o \
	./$(OBJDIR)/pathopen.o \
	./$(OBJDIR)/backend.o \
	./$(OBJDIR)/compress.o \
	./$(OBJDIR)/wildcard.o \
	./$(OBJDIR)/error.o \
	./$(OBJDIR)/mode.o

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


all : interpreter translator library backend

BUILD_DIRS=intobj/ transobj/ libobj/ backobj/ backobj/back/ intobj/back/ transobj/back/ libobj/back/

distclean : 
	-rm -r $(BUILD_DIRS)

clean : 
	@-for d in $(BUILD_DIRS); \
	do \
	    rm "$$d"*.o; \
	done
	-rm exu ecu ecu.a backendu $(DEB_SOURCE_DIR).tar.gz

.PHONY : clean distclean all

library : builddirs 
	$(MAKE) ecu.a OBJDIR=libobj ERUNTIME=1
ecu.a : $(EU_LIB_OBJECTS)
	ar -rc ecu.a $(EU_LIB_OBJECTS)
	echo $(MAKEARGS)

builddirs : $(BUILD_DIRS)

interpreter : builddirs
	$(MAKE) exu OBJDIR=intobj EBSD=$(EBSD)

translator : builddirs 
	$(MAKE) ecu OBJDIR=transobj EBSD=$(EBSD)

.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator

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

.PHONY : exusource
.PHONY : ecusource
.PHONY : backendsource
.PHONY : source

exu :  EU_TARGET = int.ex
exu :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
exu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
exu :  $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making exu
	@echo $(OS)
	$(CC) $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -oexu

ecu :  OBJDIR = transobj
ecu :  EU_TARGET = ec.ex
ecu :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
ecu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
ecu : $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making ecu
	$(CC) $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -oecu

backend : builddirs
	$(MAKE) eubackend EBACKEND=1 OBJDIR=backobj

eubackend : OBJDIR = backobj
eubackend : EU_TARGET = backend.ex
eubackend : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
eubackend : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
eubackend : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making backendu $(OBJDIR)
	$(CC) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) -oeubackend

install :
	mkdir -p $(DESTDIR)/usr/share/euphoria/include
	mkdir -p $(DESTDIR)/usr/share/doc/euphoria/html 
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/linux
	mkdir -p $(DESTDIR)/usr/share/euphoria/demo/bench
	mkdir -p $(DESTDIR)/usr/share/doc/euphoria/doc
	mkdir -p $(DESTDIR)/usr/share/euphoria/tutorial 
	mkdir -p $(DESTDIR)/usr/share/euphoria/bin 
	mkdir -p $(DESTDIR)/etc/euphoria 
	mkdir -p $(DESTDIR)/usr/share/euphoria/source 
	mkdir -p $(DESTDIR)/usr/bin 
	mkdir -p $(DESTDIR)/usr/lib
	mkdir -p $(DESTDIR)/usr/include/euphoria
	install exu ecu eubackend eubind eushroud $(DESTDIR)/usr/bin
	install ecu.a $(DESTDIR)/usr/lib
	install ../include/*  $(DESTDIR)/usr/share/euphoria/include 
	install ../include/euphoria.h $(DESTDIR)/usr/include/euphoria
	install -t $(DESTDIR)/usr/share/doc/euphoria/html ../html/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo ../demo/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/bench ../demo/bench/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar ../demo/langwar/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/langwar/Linux ../demo/langwar/Linux/*
	-install -t $(DESTDIR)/usr/share/euphoria/demo/linux ../demo/linux/*
	install -t $(DESTDIR)/usr/share/doc/euphoria/doc ../doc/*
	install -t $(DESTDIR)/usr/share/euphoria/tutorial ../tutorial/*
	install -t $(DESTDIR)/usr/share/euphoria/bin \
	           ../bin/ed.ex \
	           ../bin/ascii.ex \
	           ../bin/eprint.ex \
	           ../bin/guru.ex \
	           ../bin/key.ex \
	           ../bin/keywords.e \
	           ../bin/lines.ex \
	           ../bin/search.ex \
	           ../bin/syncolor.e \
	           ../bin/where.ex
	install -t $(DESTDIR)/usr/share/euphoria/source \
	           *.ex \
	           *.e \
	           be_*.c \
	           *.h

uninstall :
	-rm /usr/bin/exu /usr/bin/ecu /usr/lib/ecu.a
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
	$(CC) $(FE_FLAGS) ./$(OBJDIR)/$*.c -I/usr/share/euphoria -o./$(OBJDIR)/$*.o

#./$(OBJDIR)/main-.c : $(EU_MAIN)
#	echo Translating $(EU_TARGET) to create $(EU_MAIN)
#	cd ./$(OBJDIR) && exu ../ec.ex ../$(EU_TARGET)

#./$(OBJDIR)/main-.c
./$(OBJDIR)/%.c : $(EU_MAIN) 
	echo Translating $(EU_TARGET) to create $(EU_MAIN)
	-cd ./$(OBJDIR) && exu ../ec.ex ../$(EU_TARGET)

./$(OBJDIR)/back/%.o : %.c
	$(CC) $(BE_FLAGS) $*.c -o./$(OBJDIR)/back/$*.o

$(OBJDIR)/back/be_callc.o : ./be_callc.c
	$(CC) -c -w -DELINUX -fsigned-char -O2 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w -DELINUX -fsigned-char -O2 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(OBJDIR)/back/be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(RUNTIME_FLAGS) be_inline.c -o$*.o

