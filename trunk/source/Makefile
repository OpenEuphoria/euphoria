# GNU Makefile for Euphoria (Linux)
# Syntax:
#   Interpreter          (exu):  make
#   Translator           (ecu):  make translator
#   Translator Library (ecu.a):  make library

ifdef ERUNTIME
RUNTIME_FLAGS = -DERUNTIME
endif



CC = gcc
FE_FLAGS = -c -w -fsigned-char -O2 -ffast-math -fomit-frame-pointer
BE_FLAGS = -c -w -DELINUX $(RUNTIME_FLAGS) -fsigned-char -O2 -ffast-math -fomit-frame-pointer


EU_CORE_FILES = \
	main.e \
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
	compress.e \
	backend.e \
	int.ex

EU_TRANSLATOR_FILES = \
	compile.e \
	ec.ex \
	c_decl.e \
	c_out.e \
	global.e \
	traninit.e

EU_TRANSLATOR_OBJECTS = \
	ec.o \
	c_decl.o \
	c_dec0.o \
	c_dec1.o \
	c_out.o \
	compile.o \
	compil_0.o \
	compil_1.o \
	compil_2.o \
	compil_3.o \
	compil_4.o \
	compil_5.o \
	compil_6.o \
	compil_7.o \
	compil_8.o \
	compil_9.o \
	get.o \
	global.o \
	misc.o \
	sort.o \
	symtab_0.o \
	traninit.o

EU_INTERPRETER_OBJECTS =  \
	backend.o \
	compress.o 

	
EU_CORE_OBJECTS = \
	main-.o \
	main-0.o \
	pathopen.o \
	init-.o \
	wildcard.o \
	file.o \
	error.o \
	machine.o \
	symtab.o \
	scanner.o \
	scanne_0.o \
	main.o \
	emit.o \
	emit_0.o \
	emit_1.o \
	parser.o \
	parser_0.o \
	parser_1.o 

EU_CORE_C_FILES = \
	main-.c \
	main-0.c \
	pathopen.c \
	init-.c \
	wildcard.c \
	file.c \
	error.c \
	machine.c \
	symtab.c \
	scanner.c \
	scanne_0.c \
	main.c \
	emit.c \
	emit_0.c \
	emit_1.c \
	parser.c \
	parser_0.c \
	parser_1.c 
	
EU_BACKEND_OBJECTS = \
	be_execute.o \
	be_task.o \
	be_main.o \
	be_alloc.o \
	be_callc.o \
	be_inline.o \
	be_machine.o \
	be_rterror.o \
	be_syncolor.o \
	be_runtime.o \
	be_symtab.o \
	be_w.o

EU_LIB_OBJECTS = \
	be_machine.o \
	be_w.o \
	be_alloc.o \
	be_inline.o \
	be_runtime.o \
	be_task.o \
	be_callc.o

all : interpreter

clean : 
	-rm main-.c
	-rm *.o

library : ERUNTIME = -DERUNTIME 
library : $(EU_LIB_OBJECTS)
	ar -rc ecu.a $(EU_LIB_OBJECTS)
	echo $(MAKEARGS)

interpreter : exu

translator : ecu


exu :  EU_TARGET = int.ex
exu :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
exu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
exu :  main-.o $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making exu
	gcc $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm -ldl -oexu

ecu :  EU_TARGET = ec.ex
ecu :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
ecu :  EU_OBJS = $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
ecu : $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@echo making ecu
	gcc $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm -ldl -oecu

main-.o :   $(EU_MAIN)
	ecu $(EU_TARGET)
	$(CC) $(FE_FLAGS) $*.c

main-0.o :   ./main-.o 
	$(CC) $(FE_FLAGS) $*.c

global.o :  ./global.e
	$(CC) $(FE_FLAGS) $*.c

pathopen.o :   ./pathopen.e
	$(CC) $(FE_FLAGS) $*.c

init-.o :   ./main-.o
	$(CC) $(FE_FLAGS) $*.c

wildcard.o :   ./main-.o 
	$(CC) $(FE_FLAGS) $*.c

file.o :   ./main-.o
	$(CC) $(FE_FLAGS) $*.c

error.o :   ./error.e
	$(CC) $(FE_FLAGS) $*.c

machine.o :   ./main-.o
	$(CC) $(FE_FLAGS) $*.c

symtab.o :   ./symtab.e
	$(CC) $(FE_FLAGS) $*.c

symtab_0.o :   ./symtab.e
	$(CC) $(FE_FLAGS) $*.c

scanner.o :   ./scanner.e
	$(CC) $(FE_FLAGS) $*.c

scanne_0.o :   ./scanner.e
	$(CC) $(FE_FLAGS) $*.c

main.o :   ./main.e
	$(CC) $(FE_FLAGS) $*.c

emit.o :   ./emit.e 
	$(CC) $(FE_FLAGS) $*.c

emit_0.o :   ./emit.e
	$(CC) $(FE_FLAGS) $*.c

emit_1.o :   ./emit.e
	$(CC) $(FE_FLAGS) $*.c

parser.o :   ./parser.e
	$(CC) $(FE_FLAGS) $*.c

parser_0.o :   ./parser.e
	$(CC) $(FE_FLAGS) $*.c

parser_1.o :   ./parser.e
	$(CC) $(FE_FLAGS) $*.c

backend.o :   ./backend.e
	$(CC) $(FE_FLAGS) $*.c

compress.o :   ./compress.e
	$(CC) $(FE_FLAGS) $*.c

c_out.o :   ./c_out.e
	$(CC) $(FE_FLAGS) $*.c

ec.o :   ./ec.ex 
	$(CC) $(FE_FLAGS) $*.c

c_decl.o :   ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

c_dec0.o :   ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

c_dec1.o :   ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

compile.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_0.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_1.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_2.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_3.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_4.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_5.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_6.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_7.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_8.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_9.o :   ./compile.e
	$(CC) $(FE_FLAGS) $*.c

traninit.o :   ./traninit.e
	$(CC) $(FE_FLAGS) $*.c

misc.o :   ./main-.o 
	$(CC) $(FE_FLAGS) $*.c

get.o :   ./main-.o
	$(CC) $(FE_FLAGS) $*.c

sort.o :   ./main-.o
	$(CC) $(FE_FLAGS) $*.c

be_execute.o : ./be_execute.c
	$(CC) $(BE_FLAGS) $*.c

be_task.o : ./be_task.c
	$(CC) $(BE_FLAGS) $(ERUNTIME) $*.c

be_main.o : ./be_main.c
	$(CC) $(BE_FLAGS) $*.c

be_alloc.o : ./be_alloc.c
	$(CC) $(BE_FLAGS) $(ERUNTIME) $*.c

be_callc.o : ./be_callc.c
	$(CC) -c -w -DELINUX -fsigned-char -O2 -ffast-math -fno-defer-pop $*.c

be_inline.o : ./be_inline.c
	$(CC) -finline-functions $(BE_FLAGS) $(ERUNTIME) $*.c

be_machine.o : ./be_machine.c
	$(CC) $(BE_FLAGS) $(ERUNTIME)  $*.c

be_rterror.o : ./be_rterror.c
	$(CC) -c -w -DELINUX -fsigned-char -O -Os -fno-inline-functions -ffast-math -fomit-frame-pointer $*.c

be_syncolor.o : ./be_syncolor.c
	$(CC) -c -w -DELINUX -fsigned-char -O -Os -fno-inline-functions -ffast-math -fomit-frame-pointer $*.c

be_runtime.o : ./be_runtime.c
	$(CC) $(BE_FLAGS) $(ERUNTIME) $*.c
	$(CC) -S $(BE_FLAGS) $(ERUNTIME) $*.c

be_symtab.o : ./be_symtab.c
	$(CC) $(BE_FLAGS) $*.c

be_w.o : ./be_w.c
	$(CC) $(BE_FLAGS) $(ERUNTIME) $*.c


