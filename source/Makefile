# GNU Makefile for Euphoria (Linux)
# Syntax:
#   Clean up                  :  make clean
#   Everything                :  make
#   Interpreter          (exu):  make interpreter
#   Translator           (ecu):  make translator
#   Translator Library (ecu.a):  make library
#   Backend         (backendu):  make backendu

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EDEBUG
DEBUG_FLAGS=-g3
CALLC_DEBUG=-g3
else
DEBUG_FLAGS=-fomit-frame-pointer
endif

CC = gcc
FE_FLAGS =  -c -w -fsigned-char -O2 -ffast-math $(DEBUG_FLAGS) -I../
BE_FLAGS =  -c -w -DELINUX $(RUNTIME_FLAGS) -O2 -fsigned-char -ffast-math $(DEBUG_FLAGS) -DESIMPLE_MALLOC


EU_CORE_FILES = \
	common.e \
	main.e \
	mode.e \
	pathopen.e \
	error.e \
	symtab.e \
	scanner.e \
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
	int.ex

EU_TRANSLATOR_FILES = \
	compile.e \
	global.e \
	ec.ex \
	c_decl.e \
	c_out.e \
	global.e \
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
	./$(OBJDIR)/compress.o

	
EU_CORE_OBJECTS = \
	./$(OBJDIR)/main-.o \
	./$(OBJDIR)/main-0.o \
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

all : interpreter translator library backend

cleandir = -rm $(1)/*c $(1)/*o $(1)/back/*o
 
clean : 
	-rm -r intobj transobj libobj backobj
	-rm exu ecu ecu.a backendu
.PHONY : clean

library : builddirs 
	make ecu.a OBJDIR=libobj ERUNTIME=1
ecu.a : $(EU_LIB_OBJECTS)
	ar -rc ecu.a $(EU_LIB_OBJECTS)
	echo $(MAKEARGS)

builddirs : intobj/ transobj/ libobj/ backobj/ intobj/back/ transobj/back/ libobj/back/

interpreter : builddirs
	make exu OBJDIR=intobj

translator : builddirs 
	make ecu OBJDIR=transobj

.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator


exu :  EU_TARGET = int.ex
exu :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
exu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
exu :  $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making exu
	gcc $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm -ldl -oexu

ecu :  OBJDIR = transobj
ecu :  EU_TARGET = ec.ex
ecu :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
ecu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
ecu : $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making ecu
	gcc $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm -ldl -oecu

backend : builddirs
	make backendu OBJDIR=backobj

backendu : EU_TARGET = backend.ex
backendu : EU_MAIN = backend.ex compress.e mode.e pathopen.e
backendu : EU_OBJS = $(OBJDIR)/main-.o $(OBJDIR)/init-.o $(OBJDIR)/file.o $(OBJDIR)/machine.o $(OBJDIR)/0ackend.o $(OBJDIR)/pathopen.o $(OBJDIR)/backend.o $(OBJDIR)/compress.o $(OBJDIR)/mode.o
backendu : library
backendu : $(OBJDIR)/main-.o $(OBJDIR)/init-.o $(OBJDIR)/file.o $(OBJDIR)/machine.o $(OBJDIR)/0ackend.o $(OBJDIR)/pathopen.o $(OBJDIR)/backend.o $(OBJDIR)/compress.o $(OBJDIR)/mode.o
	@echo making backendu
	ls *.o
	gcc $(EU_OBJS) ecu.a -lm -ldl -obackendu

%obj : 
	mkdir $@

%back : %
	mkdir $@
	
./$(OBJDIR)/%.o : ./$(OBJDIR)/%.c
	$(CC) $(FE_FLAGS) ./$(OBJDIR)/$*.c -o./$(OBJDIR)/$*.o

./$(OBJDIR)/main-.c : $(EU_MAIN)
	cd ./$(OBJDIR) && exu ../ec.ex ../$(EU_TARGET)

./$(OBJDIR)/back/%.o : %.c
	$(CC) $(BE_FLAGS) $*.c -o./$(OBJDIR)/back/$*.o

$(OBJDIR)/back/be_callc.o : ./be_callc.c
	$(CC) -c -w -DELINUX -fsigned-char -O2 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.o
	$(CC) -S -w -DELINUX -fsigned-char -O2 -ffast-math -fno-defer-pop $(CALLC_DEBUG) be_callc.c -o$*.s

$(OBJDIR)/back/be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(RUNTIME_FLAGS) be_inline.c -o$*.o

