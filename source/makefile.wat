# OpenWatcom makefile for Euphoria (Win32)
# Syntax:
#   Interpreter       (exwc.exe):  wmake -f makefile.wat interpreter=1
#   Translator         (ecw.exe):  wmake -f makefile.wat translator=1
#   Translator Library (ecw.lib):  wmake -f makefile.wat library





EU_CORE_FILES = &
	main.e &
	pathopen.e &
	error.e &
	symtab.e &
	scanner.e &
	emit.e &
	parser.e &
	opnames.e &
	reswords.e &
	keylist.e

EU_INTERPRETER_FILES = &
	compress.e &
	backend.e &
	int.ex

EU_TRANSLATOR_FILES = &
	compile.e &
	ec.ex &
	c_decl.e &
	c_out.e &
	global.e &
	traninit.e 
	

EU_TRANSLATOR_OBJECTS = &
	ec.obj &
	c_decl.obj &
	c_dec0.obj &
	c_dec1.obj &
	c_out.obj &
	compile.obj &
	compil_0.obj &
	compil_1.obj &
	compil_2.obj &
	compil_3.obj &
	compil_4.obj &
	compil_5.obj &
	compil_6.obj &
	compil_7.obj &
	compil_8.obj &
	compil_9.obj &
	get.obj &
	global.obj &
	misc.obj &
	sort.obj &
	symtab_0.obj &
	traninit.obj &
	wildcard.obj

EU_INTERPRETER_OBJECTS =  &
	backend.obj &
	compress.obj 

	
EU_CORE_OBJECTS = &
	main-.obj &
	main-0.obj &
	pathopen.obj &
	init-.obj &
	file.obj &
	error.obj &
	machine.obj &
	symtab.obj &
	scanner.obj &
	scanne_0.obj &
	main.obj &
	emit.obj &
	emit_0.obj &
	emit_1.obj &
	parser.obj &
	parser_0.obj &
	parser_1.obj 
	

EU_BACKEND_OBJECTS = &
	be_execute.obj &
	be_task.obj &
	be_main.obj &
	be_alloc.obj &
	be_callc.obj &
	be_inline.obj &
	be_machine.obj &
	be_rterror.obj &
	be_syncolor.obj &
	be_runtime.obj &
	be_symtab.obj &
	be_w.obj

EU_LIB_OBJECTS = &
	be_machine.obj &
	be_w.obj &
	be_alloc.obj &
	be_inline.obj &
	be_runtime.obj &
	be_task.obj &
	be_callc.obj

!ifndef MANAGED_MEM
MEMFLAG = -DESIMPLE_MALLOC
!endif

!ifdef TRANSLATOR
TARGET = ecw.exe
EU_TARGET = ec.ex
EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
EU_OBJS = $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
!else
TARGET = exwc.exe
EU_TARGET = int.ex
EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
EU_OBJS = $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
!endif

all :  $(TARGET)

clean : .SYMBOLIC
	-if exist *.obj del *.obj
	-if exist *.lbc del *.lbc
	-if exist *.ilk del *.ilk
	-if exist *.pch del *.pch
	-if exist main-.c del main-.c


CC = wcc386
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG)
BE_FLAGS = /ol /dEWINDOWS /dEWATCOM  /dEOW $(%ERUNTIME) $(MEMFLAG)

library : .SYMBOLIC ecw.lib

runtime: .SYMBOLIC
	set ERUNTIME=/dERUNTIME

ecw.lib : runtime $(EU_LIB_OBJECTS)
	wlib -q ecw.lib $(EU_LIB_OBJECTS)

$(TARGET) :  $(EU_OBJS)
	@%create $(TARGET).lbc
	@%append $(TARGET).lbc option quiet
	@%append $(TARGET).lbc name $^@
	@%append $(TARGET).lbc option caseexact
	@for %i in ($(EU_OBJS)) do @%append $(TARGET).lbc file %i
	wlink SYS nt op maxe=25 op q op symf op el @$(TARGET).lbc
	wrc -q -ad exw.res $(TARGET)

main-.obj :  .MULTIPLE $(EU_MAIN)
	exwc ec -wat $(EU_TARGET)
	$(CC) $(FE_FLAGS) $*.c

main-0.obj : .MULTIPLE  .\main-0.c 
	$(CC) $(FE_FLAGS) $[@

global.obj : .MULTIPLE .\global.e
	$(CC) $(FE_FLAGS) $*.c

pathopen.obj :  .MULTIPLE ./pathopen.e
	$(CC) $(FE_FLAGS) $*.c

init-.obj :  .MULTIPLE ./init-.c 
	$(CC) $(FE_FLAGS) $[@

file.obj :  .MULTIPLE ./file.c
	$(CC) $(FE_FLAGS) $[@

error.obj :  .MULTIPLE ./error.e
	$(CC) $(FE_FLAGS) $*.c

machine.obj :  .MULTIPLE ./machine.c
	$(CC) $(FE_FLAGS) $[@

symtab.obj :  .MULTIPLE ./symtab.e
	$(CC) $(FE_FLAGS) $*.c

symtab_0.obj :  .MULTIPLE ./symtab.e
	$(CC) $(FE_FLAGS) $*.c

scanner.obj :  .MULTIPLE ./scanner.e
	$(CC) $(FE_FLAGS) $*.c

scanne_0.obj :  .MULTIPLE ./scanner.e
	$(CC) $(FE_FLAGS) $*.c

main.obj :  .MULTIPLE ./main.e
	$(CC) $(FE_FLAGS) $*.c

emit.obj :  .MULTIPLE ./emit.e 
	$(CC) $(FE_FLAGS) $*.c

emit_0.obj :  .MULTIPLE ./emit.e
	$(CC) $(FE_FLAGS) $*.c

emit_1.obj :  .MULTIPLE ./emit.e
	$(CC) $(FE_FLAGS) $*.c

parser.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $*.c

parser_0.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $*.c

parser_1.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $*.c

backend.obj :  .MULTIPLE ./backend.e
	$(CC) $(FE_FLAGS) $*.c

compress.obj :  .MULTIPLE ./compress.e
	$(CC) $(FE_FLAGS) $*.c


c_out.obj :  .MULTIPLE ./c_out.e
	$(CC) $(FE_FLAGS) $*.c

ec.obj :  .MULTIPLE ./ec.ex 
	$(CC) $(FE_FLAGS) $*.c

c_decl.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

c_dec0.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

c_dec1.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $*.c

compile.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_0.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_1.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_2.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_3.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_4.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_5.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_6.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_7.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_8.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

compil_9.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $*.c

traninit.obj :  .MULTIPLE ./traninit.e
	$(CC) $(FE_FLAGS) $*.c

misc.obj :  .MULTIPLE .\misc.c 
	$(CC) $(FE_FLAGS) $[@

get.obj :  .MULTIPLE ./get.c 
	$(CC) $(FE_FLAGS) $[@

sort.obj :  .MULTIPLE ./sort.c
	$(CC) $(FE_FLAGS) $[@

wildcard.obj :  .MULTIPLE ./wildcard.c
	$(CC) $(FE_FLAGS) $[@

be_execute.obj : ./be_execute.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS)  $[@

be_task.obj : ./be_task.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_main.obj : ./be_main.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_alloc.obj : ./be_alloc.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_callc.obj : ./be_callc.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_inline.obj : ./be_inline.c
	$(CC) /oe=40 $(BE_FLAGS) $(FE_FLAGS) $[@

be_machine.obj : ./be_machine.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_rterror.obj : ./be_rterror.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_syncolor.obj : ./be_syncolor.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_runtime.obj : ./be_runtime.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_symtab.obj : ./be_symtab.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@

be_w.obj : ./be_w.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $[@
