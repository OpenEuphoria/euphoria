# OpenWatcom makefile for Euphoria (Win32)
# Syntax:
#   Interpreter       (exwc.exe):  wmake -f makefile.wat clean interpreter
#   Translator         (ecw.exe):  wmake -f makefile.wat clean translator
#   Translator Library (ecw.lib):  wmake -f makefile.wat clean library
#   Backend       (backendw.exe):  wmake -f makefile.wat clean backend 
#                (backendwc.exe)
#               Make all targets:  wmake -f makefile.wat
#                                  wmake -f makefile.wat all
#   Options:
#                    MANAGED_MEM:  Define this to use Euphoria's memory cache.
#                                  The default is to use straight HeapAlloc/HeapFree calls. ex:
#                                      wmake -f makefile.wat interpreter MANAGED_MEM=1
#
#                          DEBUG:  Define this to build debug versions of the targets.  ex:
#                                      wmake -f makefile.wat interpreter DEBUG=1

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

EU_BACKEND_RUNNER_OBJECTS = &
	main-.obj &
	init-.obj &
	file.obj &
	machine.obj &
	0ackend.obj &
	pathopen.obj &
	backend.obj &
	compress.obj

EU_TRANSLATED_FILES =  &
	0ackend.c &
	backend.c &
	c_dec0.c &
	c_dec1.c &
	c_decl.c &
	c_out.c &
	compil_0.c &
	compil_1.c &
	compil_2.c &
	compil_3.c &
	compil_4.c &
	compil_5.c &
	compil_6.c &
	compil_7.c &
	compil_8.c &
	compil_9.c &
	compile.c &
	compress.c &
	ec.c &
	emit.c &
	emit_0.c &
	emit_1.c &
	error.c &
	file.c &
	get.c &
	global.c &
	init-.c &
	int.c &
	machine.c &
	main-.c &
	main-0.c &
	main.c &
	misc.c &
	parser.c &
	parser_0.c &
	parser_1.c &
	pathopen.c &
	scanne_0.c &
	scanner.c &
	sort.c &
	symtab.c &
	symtab_0.c &
	traninit.c &
	wildcard.c 
	
!ifndef MANAGED_MEM
MEMFLAG = -DESIMPLE_MALLOC
!endif

!ifdef DEBUG
DEBUGFLAG = /g3
!endif

all :  .SYMBOLIC
	wmake -f makefile.wat clean interpreter
	wmake -f makefile.wat clean translator
	wmake -f makefile.wat clean library
	wmake -f makefile.wat clean backend

clean : .SYMBOLIC
	-del /Q $(EU_TRANSLATED_FILES)
	-if exist *.obj del *.obj
	-if exist *.lbc del *.lbc
	-if exist *.ilk del *.ilk
	-if exist *.pch del *.pch

CC = wcc386
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG)
BE_FLAGS = /ol /dEWINDOWS /dEWATCOM  /dEOW $(%ERUNTIME) $(MEMFLAG) $(DEBUGFLAG)

library : .SYMBOLIC ecw.lib

runtime: .SYMBOLIC
	set ERUNTIME=/dERUNTIME

ecw.lib : runtime $(EU_LIB_OBJECTS)
	wlib -q ecw.lib $(EU_LIB_OBJECTS)


interpreter_objects : .SYMBOLIC int.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create int.lbc
	@%append int.lbc option quiet
	@%append int.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append int.lbc file %i

exw.exe : interpreter_objects 
	wlink SYS nt_win op maxe=25 op q op symf op el @int.lbc name exw.exe
	wrc -q -ad exw.res exw.exe

exwc.exe : interpreter_objects 
	wlink SYS nt op maxe=25 op q op symf op el @int.lbc name exwc.exe
	wrc -q -ad exw.res exwc.exe

interpreter : .SYMBOLIC exw.exe exwc.exe

install : .SYMBOLIC
	copy ecw.exe $(%EUDIR)\bin\
	copy exw.exe $(%EUDIR)\bin\
	copy exwc.exe $(%EUDIR)\bin\
	copy backendw.exe $(%EUDIR)\bin\
	copy backendc.exe $(%EUDIR)\bin\
	copy ecw.lib $(%EUDIR)\bin\
	
ecw.exe : ec.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create ec.lbc
	@%append ec.lbc option quiet
	@%append ec.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append ec.lbc file %i
	wlink SYS nt op maxe=25 op q op symf op el @ec.lbc name ecw.exe
	wrc -q -ad exw.res ecw.exe

translator : .SYMBOLIC ecw.exe

backendw.exe : backend.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create exwb.lbc
	@%append exwb.lbc option quiet
	@%append exwb.lbc option caseexact
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append exwb.lbc file %i
	wlink SYS nt_win op maxe=25 op q op symf op el @exwb.lbc name backendw.exe
	wrc -q -ad exw.res backendw.exe
	wlink SYS nt op maxe=25 op q op symf op el @exwb.lbc name backendc.exe
	wrc -q -ad exw.res backendc.exe
		
backend : .SYMBOLIC backendw.exe

int.c : int.ex $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
	exwc.exe ec.ex int.ex
	
ec.c : ec.ex $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
	exwc.exe ec.ex ec.ex

backend.c : backend.ex $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
	exwc.exe ec.ex backend.ex

main-.obj :  .MULTIPLE
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

0ackend.obj :  .MULTIPLE ./backend.e
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
