# OpenWatcom makefile for Euphoria (Win32)
# Syntax:
#   Interpreter(exw.exe, exwc.exe):  wmake -f makefile.wat interpreter
#   Translator           (ecw.exe):  wmake -f makefile.wat translator
#   Translator Library   (ecw.lib):  wmake -f makefile.wat library
#   Backend         (backendw.exe):  wmake -f makefile.wat backend 
#                   (backendc.exe)
#                 Make all targets:  wmake -f makefile.wat
#                                    wmake -f makefile.wat all
#          Make all Win32 Binaries:  wmake -f makefile.wat winall
#          Make all Dos32 Binaries:  wmake -f makefile.wat dosall
#
#   Options:
#                    MANAGED_MEM:  Define this to use Euphoria's memory cache.
#                                  The default is to use straight HeapAlloc/HeapFree calls. ex:
#                                      wmake -f makefile.wat interpreter MANAGED_MEM=1
#
#                          DEBUG:  Define this to build debug versions of the targets.  ex:
#                                      wmake -f makefile.wat interpreter DEBUG=1

EU_CORE_FILES = &
	main.e &
	mode.e &
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
	c_out.e &
	int.ex

EU_TRANSLATOR_FILES = &
	compile.e &
	ec.ex &
	c_decl.e &
	c_out.e &
	global.e &
	traninit.e 
	

EU_TRANSLATOR_OBJECTS = &
	.\$(OBJDIR)\ec.obj &
	.\$(OBJDIR)\c_decl.obj &
	.\$(OBJDIR)\c_dec0.obj &
	.\$(OBJDIR)\c_dec1.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\compile.obj &
	.\$(OBJDIR)\compil_0.obj &
	.\$(OBJDIR)\compil_1.obj &
	.\$(OBJDIR)\compil_2.obj &
	.\$(OBJDIR)\compil_3.obj &
	.\$(OBJDIR)\compil_4.obj &
	.\$(OBJDIR)\compil_5.obj &
	.\$(OBJDIR)\compil_6.obj &
	.\$(OBJDIR)\compil_7.obj &
	.\$(OBJDIR)\compil_8.obj &
	.\$(OBJDIR)\compil_9.obj &
	.\$(OBJDIR)\compil_A.obj &
	.\$(OBJDIR)\get.obj &
	.\$(OBJDIR)\global.obj &
	.\$(OBJDIR)\misc.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\symtab_0.obj &
	.\$(OBJDIR)\traninit.obj &
	.\$(OBJDIR)\wildcard.obj

EU_INTERPRETER_OBJECTS =  &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\symtab_0.obj 

	
EU_CORE_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\main-0.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\file.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\symtab.obj &
	.\$(OBJDIR)\scanner.obj &
	.\$(OBJDIR)\scanne_0.obj &
	.\$(OBJDIR)\main.obj &
	.\$(OBJDIR)\emit.obj &
	.\$(OBJDIR)\emit_0.obj &
	.\$(OBJDIR)\emit_1.obj &
	.\$(OBJDIR)\parser.obj &
	.\$(OBJDIR)\parser_0.obj &
	.\$(OBJDIR)\parser_1.obj 
	

EU_BACKEND_OBJECTS = &
	.\$(OBJDIR)\back\be_execute.obj &
	.\$(OBJDIR)\back\be_task.obj &
	.\$(OBJDIR)\back\be_main.obj &
	.\$(OBJDIR)\back\be_alloc.obj &
	.\$(OBJDIR)\back\be_callc.obj &
	.\$(OBJDIR)\back\be_inline.obj &
	.\$(OBJDIR)\back\be_machine.obj &
	.\$(OBJDIR)\back\be_rterror.obj &
	.\$(OBJDIR)\back\be_syncolor.obj &
	.\$(OBJDIR)\back\be_runtime.obj &
	.\$(OBJDIR)\back\be_symtab.obj &
	.\$(OBJDIR)\back\be_w.obj

EU_LIB_OBJECTS = &
	.\$(OBJDIR)\back\be_machine.obj &
	.\$(OBJDIR)\back\be_w.obj &
	.\$(OBJDIR)\back\be_alloc.obj &
	.\$(OBJDIR)\back\be_inline.obj &
	.\$(OBJDIR)\back\be_runtime.obj &
	.\$(OBJDIR)\back\be_task.obj &
	.\$(OBJDIR)\back\be_callc.obj

EU_BACKEND_RUNNER_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\file.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\0ackend.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\compress.obj

EU_DOS_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\main-0.obj &
	.\$(OBJDIR)\int.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\symtab.obj &
	.\$(OBJDIR)\symtab_0.obj &
	.\$(OBJDIR)\scanner.obj &
	.\$(OBJDIR)\scanne_0.obj &
	.\$(OBJDIR)\file.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\emit.obj &
	.\$(OBJDIR)\emit_0.obj &
	.\$(OBJDIR)\emit_1.obj &
	.\$(OBJDIR)\parser.obj &
	.\$(OBJDIR)\parser_0.obj &
	.\$(OBJDIR)\parser_1.obj &
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\main.obj &
	.\$(OBJDIR)\init-.obj 
	
!ifeq MANAGED_MEM=1
MEMFLAG = -DESIMPLE_MALLOC
!endif

!ifeq DEBUG 1
DEBUGFLAG = /g3
!endif

all :  .SYMBOLIC
	wmake -f makefile.wat winall
	wmake -f makefile.wat dosall

winall : .SYMBOLIC
	wmake -f makefile.wat interpreter
	wmake -f makefile.wat translator
	wmake -f makefile.wat library
	wmake -f makefile.wat backend

dosall : .SYMBOLIC
	wmake -f makefile.wat dos
	wmake -f makefile.wat library OS=DOS

clean : .SYMBOLIC
	-del /Q exw.exe exwc.exe ecw.lib backendw.exe main-.h
	-del /Q /S intobj\* transobj\* libobj\* backobj\* dosobj\* doslibobj\*

!ifeq OS DOS
OSFLAG=EDOS
LIBTARGET=ec.lib
!else
OSFLAG=EWINDOWS
LIBTARGET=ecw.lib
!endif

CC = wcc386
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG)
BE_FLAGS = /ol /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(MEMFLAG) $(DEBUGFLAG)

builddirs : .SYMBOLIC
	if not exist intobj mkdir intobj
	if not exist transobj mkdir transobj
	if not exist libobj mkdir libobj
	if not exist backobj mkdir backobj
	if not exist intobj\back mkdir intobj\back
	if not exist transobj\back mkdir transobj\back
	if not exist libobj\back mkdir libobj\back
	if not exist dosobj mkdir dosobj
	if not exist dosobj\back mkdir dosobj\back
	if not exist doslibobj mkdir doslibobj
	if not exist doslibobj\back mkdir doslibobj\back
	
library : .SYMBOLIC builddirs
	wmake -f makefile.wat $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

runtime: .SYMBOLIC 
	set ERUNTIME=/dERUNTIME

ecw.lib : runtime $(EU_LIB_OBJECTS)
	wlib -q ecw.lib $(EU_LIB_OBJECTS)

ec.lib : runtime $(EU_LIB_OBJECTS)
	

interpreter_objects : .SYMBOLIC $(OBJDIR)\int.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\int.lbc
	@%append .\$(OBJDIR)\int.lbc option quiet
	@%append .\$(OBJDIR)\int.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\int.lbc file %i

exw.exe : interpreter_objects 
	wlink SYS nt_win op maxe=25 op q op symf op el @.\$(OBJDIR)\int.lbc name exw.exe
	wrc -q -ad exw.res exw.exe

exwc.exe : interpreter_objects 
	wlink SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\int.lbc name exwc.exe
	wrc -q -ad exw.res exwc.exe

interpreter : .SYMBOLIC builddirs 
	wmake -f makefile.wat exw.exe EX=exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -f makefile.wat exwc.exe EX=exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

install : .SYMBOLIC
	copy ecw.exe $(%EUDIR)\bin\
	copy exw.exe $(%EUDIR)\bin\
	copy exwc.exe $(%EUDIR)\bin\
	copy backendw.exe $(%EUDIR)\bin\
	copy backendc.exe $(%EUDIR)\bin\
	copy ecw.lib $(%EUDIR)\bin\
	
ecw.exe : $(OBJDIR)\ec.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ec.lbc
	@%append .\$(OBJDIR)\ec.lbc option quiet
	@%append .\$(OBJDIR)\ec.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ec.lbc file %i
	wlink SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\ec.lbc name ecw.exe
	wrc -q -ad exw.res ecw.exe


translator : .SYMBOLIC builddirs
	wmake -f makefile.wat ecw.exe EX=exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

backendw.exe : $(OBJDIR)\backend.c $(EU_BACKEND_RUNNER_OBJECTS)
	@%create .\$(OBJDIR)\exwb.lbc
	@%append .\$(OBJDIR)\exwb.lbc option quiet
	@%append .\$(OBJDIR)\exwb.lbc option caseexact
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) ecw.lib) do @%append .\$(OBJDIR)\exwb.lbc file %i
	wlink SYS nt_win op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendw.exe
	wrc -q -ad exw.res backendw.exe
	wlink SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendc.exe
	wrc -q -ad exw.res backendc.exe


backend : .SYMBOLIC builddirs
	wmake -f makefile.wat backendw.exe EX=exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dos : .SYMBOLIC builddirs
	wmake -f makefile.wat ex.exe EX=ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

ex.exe : $(OBJDIR)\int.c $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ex.lbc
	@%append .\$(OBJDIR)\ex.lbc option quiet
	@%append .\$(OBJDIR)\ex.lbc option caseexact
	@%append .\$(OBJDIR)\ex.lbc option osname='CauseWay'
	@%append .\$(OBJDIR)\ex.lbc libpath C:\WATCOM\lib386
	@%append .\$(OBJDIR)\ex.lbc libpath C:\WATCOM\lib386\dos
	@%append .\$(OBJDIR)\ex.lbc OPTION stub=C:\euphoria\bin\cwstub.exe
	@%append .\$(OBJDIR)\ex.lbc format os2 le ^
	@%append .\$(OBJDIR)\ex.lbc OPTION STACK=262144
	@%append .\$(OBJDIR)\ex.lbc OPTION QUIET
	@%append .\$(OBJDIR)\ex.lbc OPTION ELIMINATE
	@%append .\$(OBJDIR)\ex.lbc OPTION CASEEXACT
	@for %i in ($(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ex.lbc file %i
	wlink @.\$(OBJDIR)\ex.lbc name ex.exe
	le23p ex.exe
	cwc ex.exe


.\$(OBJDIR)\main-.c : .\$(OBJDIR)\$(EU_TARGET)c
	cd .\$(OBJDIR)
	$(EX) ..\ec.ex ..\$(EU_TARGET)ex
	cd ..

$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex
	cd .\$(OBJDIR)
	$(EX) ..\ec.ex ..\$(EU_TARGET)ex
	cd ..

.\$(OBJDIR)\int.obj :  .\$(OBJDIR)\int.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\main-.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\main-0.obj : $(OBJDIR)\main-0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@


.\$(OBJDIR)\mode.obj : $(OBJDIR)\mode.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@
	
.\$(OBJDIR)\global.obj :.\global.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\pathopen.obj :  .MULTIPLE ./pathopen.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\init-.obj :  .MULTIPLE ./$(OBJDIR)\init-.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\file.obj :  .MULTIPLE ./$(OBJDIR)\file.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\error.obj :  .MULTIPLE ./error.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\machine.obj :  .MULTIPLE ./$(OBJDIR)/machine.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\symtab.obj :  .MULTIPLE ./symtab.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\symtab_0.obj :  .MULTIPLE ./symtab.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scanner.obj :  .MULTIPLE ./scanner.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scanne_0.obj :  .MULTIPLE ./scanner.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@
	
.\$(OBJDIR)\main.obj :  .MULTIPLE ./main.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit.obj :  .MULTIPLE ./emit.e 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit_0.obj :  .MULTIPLE ./emit.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit_1.obj :  .MULTIPLE ./emit.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_0.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_1.obj :  .MULTIPLE ./parser.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\0ackend.obj :  .MULTIPLE ./backend.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\backend.obj :  .MULTIPLE ./backend.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compress.obj :  .MULTIPLE ./compress.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_out.obj :  .MULTIPLE ./c_out.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\ec.obj :  .MULTIPLE ./ec.ex 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_decl.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_dec0.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_dec1.obj :  .MULTIPLE ./c_decl.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compile.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_0.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_1.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_2.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_3.obj :  .MULTIPLE ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_4.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_5.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_6.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_7.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_8.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_9.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_A.obj :  ./compile.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\traninit.obj :  ./traninit.e
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\misc.obj : .\$(OBJDIR)\main-.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\get.obj :  .\$(OBJDIR)\main-.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\sort.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\wildcard.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\back\be_execute.obj : ./be_execute.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS)  $^&.c -fo=.\$(OBJDIR)\back\$^.

.\$(OBJDIR)\back\be_task.obj : ./be_task.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_main.obj : ./be_main.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_alloc.obj : ./be_alloc.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_callc.obj : ./be_callc.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_inline.obj : ./be_inline.c
	$(CC) /oe=40 $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_machine.obj : ./be_machine.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_rterror.obj : ./be_rterror.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_syncolor.obj : ./be_syncolor.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_runtime.obj : ./be_runtime.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_symtab.obj : ./be_symtab.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_w.obj : ./be_w.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@
