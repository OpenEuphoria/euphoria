# OpenWatcom makefile for Euphoria (Win32/DOS32)
#
# You must first run configure.bat, supplying any options you might need:
#     --with-eu3      Use this option if you are building Euphoria with only 
#                     a version of Euphoria less than 4.  It will use the EUINC
#                     variable instead of passing the include directory on the
#                     command line.
# 
#     --prefix <dir>  Use this option to specify the location for euphoria to
#                     be installed.  The default is EUDIR, or c:\euphoria,
#                     if EUDIR is not set.
#
# Syntax:
#   Interpreter(exw.exe, exwc.exe):  wmake -f makefile.wat interpreter
#   Translator    (ec.exe ecw.exe):  wmake -f makefile.wat translator
#   Translator Library   (ec.lib ecw.lib):  wmake -f makefile.wat library
#   Backend         (backendw.exe):  wmake -f makefile.wat backend 
#                   (backendc.exe)
#                 Make all targets:  wmake -f makefile.wat
#                                    wmake -f makefile.wat all
#          Make all Win32 Binaries:  wmake -f makefile.wat winall
#          Make all Dos32 Binaries:  wmake -f makefile.wat dosall
#
#    Make a source zip that can be   wmake -f makefile.wat source [SVN_REV=r]
#       built with just a compiler   wmake -f makefile.wat source-win [SVN_REV=r]
#     Note that source builds both   wmake -f makefile.wat source-dos [SVN_REV=r]
#        source-win and source-dos.
#
#      Install binaries, source and 
#                    include files:
#             Windows and dos files  wmake -f makefile.wat install
#                Windows files only  wmake -f makefile.wat installwin
#                    dos files only  wmake -f makefile.wat installdos
#
#                   Run unit tests:
#                     Win32 and DOS  wmake -f makefile.wat test
#                        Win32 Only  wmake -f makefile.wat testwin
#                          DOS Only  wmake -f makefile.wat testdos
#
# The source targets will create a subdirectory called euphoria-r$(SVN_REV). 
# The default for SVN_REV is 'xxx'.
#
#
#   Options:
#                    MANAGED_MEM:  Set this to 1 to use Euphoria's memory cache.
#                                  The default is to use straight HeapAlloc/HeapFree calls. ex:
#                                      wmake -f makefile.wat interpreter MANAGED_MEM=1
#
#                          DEBUG:  Set this to 1 to build debug versions of the targets.  ex:
#                                      wmake -f makefile.wat interpreter DEBUG=1

!include config.wat

EU_CORE_FILES = &
	rev.e &
	main.e &
	global.e &
	common.e &
	mode.e &
	pathopen.e &
	error.e &
	symtab.e &
	scanner.e &
	scientific.e &
	emit.e &
	parser.e &
	opnames.e &
	reswords.e &
	keylist.e

EU_INTERPRETER_FILES = &
	compress.e &
	backend.e &
	c_out.e &
	cominit.e &
	intinit.e &
	int.ex

EU_TRANSLATOR_FILES = &
	compile.e &
	ec.ex &
	c_decl.e &
	c_out.e &
	cominit.e &
	traninit.e &
	tranplat.e &
	compress.e
	
EU_TRANSLATOR_OBJECTS = &
	.\$(OBJDIR)\ec.obj &
        .\$(OBJDIR)\0rror.obj &
	.\$(OBJDIR)\c_decl.obj &
	.\$(OBJDIR)\c_dec0.obj &
	.\$(OBJDIR)\c_dec1.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\cominit.obj &
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
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\get.obj &
	.\$(OBJDIR)\global.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\symtab_0.obj &
	.\$(OBJDIR)\traninit.obj &
	.\$(OBJDIR)\tranplat.obj &
	.\$(OBJDIR)\wildcard.obj &
	.\$(OBJDIR)\sequence.obj &
	.\$(OBJDIR)\text.obj &
	.\$(OBJDIR)\search.obj &
	.\$(OBJDIR)\math.obj &
	.\$(OBJDIR)\os.obj &
	.\$(OBJDIR)\types.obj &
	.\$(OBJDIR)\dll.obj &
	.\$(OBJDIR)\filesys.obj &
	.\$(OBJDIR)\io.obj

EU_INTERPRETER_OBJECTS =  &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\cominit.obj &
	.\$(OBJDIR)\intinit.obj &
	.\$(OBJDIR)\symtab_0.obj &
	.\$(OBJDIR)\0rror.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\get.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\wildcard.obj &
	.\$(OBJDIR)\sequence.obj &
	.\$(OBJDIR)\text.obj &
	.\$(OBJDIR)\tranplat.obj &
	.\$(OBJDIR)\types.obj &
	.\$(OBJDIR)\dll.obj &
	.\$(OBJDIR)\filesys.obj

	
EU_CORE_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\main-0.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\symtab.obj &
	.\$(OBJDIR)\scanner.obj &
	.\$(OBJDIR)\scientific.obj &
	.\$(OBJDIR)\scanne_0.obj &
	.\$(OBJDIR)\main.obj &
	.\$(OBJDIR)\emit.obj &
	.\$(OBJDIR)\emit_0.obj &
	.\$(OBJDIR)\emit_1.obj &
	.\$(OBJDIR)\parser.obj &
	.\$(OBJDIR)\parser_0.obj &
	.\$(OBJDIR)\parser_1.obj &
	.\$(OBJDIR)\parser_2.obj &
	.\$(OBJDIR)\parser_3.obj

EU_BACKEND_OBJECTS = &
	.\$(OBJDIR)\back\be_execute.obj &
	.\$(OBJDIR)\back\be_decompress.obj &
	.\$(OBJDIR)\back\be_task.obj &
	.\$(OBJDIR)\back\be_main.obj &
	.\$(OBJDIR)\back\be_alloc.obj &
	.\$(OBJDIR)\back\be_callc.obj &
	.\$(OBJDIR)\back\be_inline.obj &
	.\$(OBJDIR)\back\be_machine.obj &
	.\$(OBJDIR)\back\be_pcre.obj &
	.\$(OBJDIR)\back\be_rterror.obj &
	.\$(OBJDIR)\back\be_syncolor.obj &
	.\$(OBJDIR)\back\be_runtime.obj &
	.\$(OBJDIR)\back\be_symtab.obj &
	.\$(OBJDIR)\back\be_w.obj

EU_LIB_OBJECTS = &
	.\$(OBJDIR)\back\be_decompress.obj &
	.\$(OBJDIR)\back\be_machine.obj &
	.\$(OBJDIR)\back\be_w.obj &
	.\$(OBJDIR)\back\be_alloc.obj &
	.\$(OBJDIR)\back\be_inline.obj &
	.\$(OBJDIR)\back\be_runtime.obj &
	.\$(OBJDIR)\back\be_task.obj &
	.\$(OBJDIR)\back\be_pcre.obj &
	.\$(OBJDIR)\back\be_callc.obj

EU_BACKEND_RUNNER_FILES = &
	.\$(OBJDIR)\backend.ex &
	.\$(OBJDIR)\wildcard.e &
	.\$(OBJDIR)\compress.e

EU_BACKEND_RUNNER_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\cominit.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\intinit.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\0ackend.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\text.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\types.obj &
        .\$(OBJDIR)\compress.obj &
        .\$(OBJDIR)\dll.obj &
        .\$(OBJDIR)\io.obj &
        .\$(OBJDIR)\filesys.obj

EU_DOSBACKEND_RUNNER_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\cominit.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\intinit.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\0ackend.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\text.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\types.obj &
        .\$(OBJDIR)\compress.obj &
        .\$(OBJDIR)\io.obj &
        .\$(OBJDIR)\filesys.obj

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
	.\$(OBJDIR)\scientif.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\emit.obj &
	.\$(OBJDIR)\emit_0.obj &
	.\$(OBJDIR)\emit_1.obj &
	.\$(OBJDIR)\parser.obj &
	.\$(OBJDIR)\parser_0.obj &
	.\$(OBJDIR)\parser_1.obj &
	.\$(OBJDIR)\parser_2.obj &
	.\$(OBJDIR)\parser_3.obj &
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\backend.obj &
	.\$(OBJDIR)\tranplat.obj &
	.\$(OBJDIR)\cominit.obj &
	.\$(OBJDIR)\intinit.obj &
	.\$(OBJDIR)\wildcard.obj &
	.\$(OBJDIR)\sequence.obj &
	.\$(OBJDIR)\text.obj &
	.\$(OBJDIR)\get.obj &
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\main.obj &
        .\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\0rror.obj &
        .\$(OBJDIR)\filesys.obj &
        .\$(OBJDIR)\types.obj

EU_TRANSDOS_OBJECTS = &
	.\$(OBJDIR)\main-.obj &
	.\$(OBJDIR)\main-0.obj &
	.\$(OBJDIR)\pathopen.obj &
	.\$(OBJDIR)\init-.obj &
	.\$(OBJDIR)\error.obj &
	.\$(OBJDIR)\machine.obj &
	.\$(OBJDIR)\mode.obj &
	.\$(OBJDIR)\symtab.obj &
	.\$(OBJDIR)\scanner.obj &
	.\$(OBJDIR)\scientif.obj &
	.\$(OBJDIR)\scanne_0.obj &
	.\$(OBJDIR)\main.obj &
	.\$(OBJDIR)\emit.obj &
	.\$(OBJDIR)\emit_0.obj &
	.\$(OBJDIR)\emit_1.obj &
	.\$(OBJDIR)\parser.obj &
	.\$(OBJDIR)\parser_0.obj &
	.\$(OBJDIR)\parser_1.obj &
	.\$(OBJDIR)\parser_2.obj &
	.\$(OBJDIR)\parser_3.obj &
	.\$(OBJDIR)\ec.obj &
	.\$(OBJDIR)\c_decl.obj &
	.\$(OBJDIR)\c_dec0.obj &
	.\$(OBJDIR)\c_dec1.obj &
	.\$(OBJDIR)\c_out.obj &
	.\$(OBJDIR)\cominit.obj &
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
	.\$(OBJDIR)\sort.obj &
	.\$(OBJDIR)\compress.obj &
	.\$(OBJDIR)\symtab_0.obj &
	.\$(OBJDIR)\traninit.obj &
	.\$(OBJDIR)\tranplat.obj &
	.\$(OBJDIR)\wildcard.obj &
	.\$(OBJDIR)\sequence.obj &
	.\$(OBJDIR)\text.obj &
        .\$(OBJDIR)\search.obj &
        .\$(OBJDIR)\io.obj &
        .\$(OBJDIR)\math.obj &
        .\$(OBJDIR)\os.obj &
	.\$(OBJDIR)\0rror.obj &
        .\$(OBJDIR)\filesys.obj &
        .\$(OBJDIR)\types.obj

PCRE_OBJECTS = &
	.\pcre\pcre_chartables.obj &
	.\pcre\pcre_compile.obj &
	.\pcre\pcre_config.obj &
	.\pcre\pcre_dfa_exec.obj &
	.\pcre\pcre_exec.obj &
	.\pcre\pcre_fullinfo.obj &
	.\pcre\pcre_get.obj &
	.\pcre\pcre_globals.obj &
	.\pcre\pcre_info.obj &
	.\pcre\pcre_maketables.obj &
	.\pcre\pcre_newline.obj &
	.\pcre\pcre_ord2utf8.obj &
	.\pcre\pcre_refcount.obj &
	.\pcre\pcre_study.obj &
	.\pcre\pcre_tables.obj &
	.\pcre\pcre_try_flipped.obj &
	.\pcre\pcre_ucp_searchfuncs.obj &
	.\pcre\pcre_valid_utf8.obj &
	.\pcre\pcre_version.obj &
	.\pcre\pcre_xclass.obj


!ifneq MANAGED_MEM 1
MEMFLAG = /dESIMPLE_MALLOC
!endif

!ifndef PREFIX
!ifneq PREFIX ""
PREFIX=$(%EUDIR)
!else
PREFIX=C:\euphoria
!endif
!endif

!ifeq INT_CODES 1
#TODO hack
MEMFLAG = $(MEMFLAG) /dINT_CODES
!endif

!ifeq DEBUG 1
DEBUGFLAG = /d2 /dDEBUG
DEBUGLINK = debug all
!endif

#.\$(OBJDIR)\compress.obj &
!ifeq EU3 1
#TODO figure out how to fix this on windows 98 where command.com doesnt support &&
EXE=set EUINC=$(PWD)\..\include && $(EX)
#EXE=$(EX)
INCDIR=
!else
EXE=$(EX)
INCDIR=-i ..\..\include
!endif

VARS=DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
all :  .SYMBOLIC
    @echo ------- ALL -----------
	wmake -f makefile.wat winall $(VARS)
	wmake -f makefile.wat dosall $(VARS)

winall : .SYMBOLIC
    @echo ------- WINALL -----------
	wmake -f makefile.wat interpreter $(VARS)
	wmake -f makefile.wat translator $(VARS)
	wmake -f makefile.wat library $(VARS)
	wmake -f makefile.wat backend $(VARS)

dosall : .SYMBOLIC
    @echo ------- DOSALL -----------
	wmake -f makefile.wat dos $(VARS)
	wmake -f makefile.wat library OS=DOS $(VARS)
	wmake -f makefile.wat dostranslator OS=DOS $(VARS)
	wmake -f makefile.wat dosbackend OS=DOS $(VARS)

BUILD_DIRS=intobj transobj libobj backobj

#TODO make this smarter
distclean : .SYMBOLIC
	-if not exist $(%WINDIR)\command\deltree.exe rmdir /Q/S $(BUILD_DIRS)
	-if not exist $(%WINDIR)\command\deltree.exe del /Q config.wat rev.e
	-if exist $(%WINDIR)\command\deltree.exe deltree /y $(BUILD_DIRS)
	-if exist $(%WINDIR)\command\deltree.exe deltree /y config.wat rev.e

#TODO make this smarter
clean : .SYMBOLIC
	-if not exist $(%WINDIR)\command\deltree.exe del /Q &
		ex.exe ec.exe exw.exe exwc.exe ecw.exe ec.lib ecw.lib backendw.exe backendc.exe backendd.exe main-.h
	-if not exist $(%WINDIR)\command\deltree.exe del /Q /S &
		intobj\* transobj\* libobj\* backobj\* dosobj\* doslibobj\*
	-if not exist $(%WINDIR)\command\deltree.exe del /Q &
		.\pcre\*.obj .\pcre\config.h .\pcre\pcre.h &
	    .\pcre\pcre_chartables.c 
	-if exist $(%WINDIR)\command\deltree.exe deltree /y &
		ex.exe ec.exe exw.exe exwc.exe ecw.exe ec.lib ecw.lib backendw.exe backendc.exe backendd.exe main-.h
	-if exist $(%WINDIR)\command\deltree.exe deltree /y &
		intobj\* transobj\* libobj\* backobj\* dosobj\* doslibobj\*
	-if exist $(%WINDIR)\command\deltree.exe deltree /y &
		.\pcre\*.obj .\pcre\config.h .\pcre\pcre.h &
	    .\pcre\pcre_chartables.c 

!ifeq OS DOS
OSFLAG=EDOS
LIBTARGET=ec.lib
!else
OSFLAG=EWINDOWS
LIBTARGET=ecw.lib
!endif

CC = wcc386
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG) /I..\
BE_FLAGS = /ol /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(%EBACKEND) $(MEMFLAG) $(DEBUGFLAG)
PCRE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /dHAVE_CONFIG_H

builddirs : .SYMBOLIC
	if not exist intobj mkdir intobj
	if not exist transobj mkdir transobj
	if not exist libobj mkdir libobj
	if not exist backobj mkdir backobj
	if not exist backobj\back mkdir backobj\back
	if not exist intobj\back mkdir intobj\back
	if not exist transobj\back mkdir transobj\back
	if not exist libobj\back mkdir libobj\back
	if not exist dosobj mkdir dosobj
	if not exist dosobj\back mkdir dosobj\back
	if not exist doslibobj mkdir doslibobj
	if not exist doslibobj\back mkdir doslibobj\back
	if not exist dostrobj mkdir dostrobj
	if not exist dostrobj\back mkdir dostrobj\back
	if not exist dosbkobj mkdir dosbkobj
	if not exist dosbkobj\back mkdir dosbkobj\back
	
library : .SYMBOLIC builddirs
    @echo ------- LIBRARY -----------
	wmake -f makefile.wat $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

runtime: .SYMBOLIC 
    @echo ------- RUNTIME -----------
	set ERUNTIME=/dERUNTIME

backendflag: .SYMBOLIC
	set EBACKEND=/dBACKEND

ecw.lib : runtime $(PCRE_OBJECTS) $(EU_LIB_OBJECTS)
	wlib -q ecw.lib $(PCRE_OBJECTS) $(EU_LIB_OBJECTS)

ec.lib : runtime $(PCRE_OBJECTS) $(EU_LIB_OBJECTS)
	wlib -q ec.lib $(PCRE_OBJECTS) $(EU_LIB_OBJECTS)
	
pcre : .SYMBOLIC .\pcre\pcre.h .\pcre\config.h $(PCRE_OBJECTS)

interpreter_objects : .SYMBOLIC rev.e $(OBJDIR)\int.c pcre $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\int.lbc
	@%append .\$(OBJDIR)\int.lbc option quiet
	@%append .\$(OBJDIR)\int.lbc option caseexact
	@for %i in ($(PCRE_OBJECTS) $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\int.lbc file %i

exwsource : .SYMBOLIC .\$(OBJDIR)/main-.c
ecwsource : .SYMBOLIC .\$(OBJDIR)/main-.c
backendsource : .SYMBOLIC .\$(OBJDIR)/main-.c
ecsource : .SYMBOLIC .\$(OBJDIR)/main-.c
exsource : .SYMBOLIC .\$(OBJDIR)/main-.c

translate-win : .SYMBOLIC  builddirs
    @echo ------- TRANSLATE WIN -----------
        wmake -f makefile.wat exwsource EX=exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat ecwsource EX=exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat backendsource EX=exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	
translate-dos : .SYMBOLIC builddirs
    @echo ------- TRANSLATE DOS -----------
	wmake -f makefile.wat exsource EX=ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -f makefile.wat exsource EX=ec.exe EU_TARGET=int. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
        wmake -f makefile.wat backendsource EX=ex.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	
translate : .SYMBOLIC translate-win translate-dos
	
SVN_REV=xxx
SOURCEDIR= euphoria-r$(SVN_REV)

common-source : .SYMBOLIC
	if exist $(SOURCEDIR) rmdir /Q /S $(SOURCEDIR)
	mkdir $(SOURCEDIR)
	mkdir $(SOURCEDIR)\pcre
	copy configure.bat $(SOURCEDIR)
	copy makefile.wat $(SOURCEDIR)
	copy pcre\* $(SOURCEDIR)\pcre
	copy int.ex $(SOURCEDIR)
	copy ec.ex $(SOURCEDIR)
	copy backend.ex $(SOURCEDIR)
	copy *.e $(SOURCEDIR)
	copy *res $(SOURCEDIR)
	copy be_*.c $(SOURCEDIR)
	copy *.h $(SOURCEDIR)
	copy ..\include\euphoria.h $(SOURCEDIR)

source-win : .SYMBOLIC translate-win common-source
	mkdir $(SOURCEDIR)\intobj
	mkdir $(SOURCEDIR)\transobj
	mkdir $(SOURCEDIR)\backobj
	copy intobj\* $(SOURCEDIR)\intobj
	copy transobj\* $(SOURCEDIR)\transobj
	copy backobj\* $(SOURCEDIR)\backobj
	
source-dos : .SYMBOLIC translate-dos common-source
	mkdir $(SOURCEDIR)\dosobj
	mkdir $(SOURCEDIR)\doslibobj
	mkdir $(SOURCEDIR)\dostrobj
	mkdir $(SOURCEDIR)\dosbkobj
	copy dosobj\* $(SOURCEDIR)
	copy doslibobj\* $(SOURCEDIR)
	copy dostrobj\* $(SOURCEDIR)
	copy dosbkobj\* $(SOURCEDIR)
	
source : .SYMBOLIC common-source source-win source-dos

testwin : .SYMBOLIC interpreter 
	cd ..\tests
	..\source\exwc -i ..\include ..\bin\eutest.ex -exe ..\source\exwc.exe -ec ..\source\ecw.exe -lib ..\source\ecw.lib
	cd ..\source

testdos : .SYMBOLIC dos
	cd ..\tests
	..\source\ex -i ..\include ..\bin\eutest.ex -exe ..\source\ex.exe -ec ..\source\ec.exe -lib ..\source\ec.lib
	cd ..\source
	
test : .SYMBOLIC testwin testdos
	

exw.exe : interpreter_objects 
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @.\$(OBJDIR)\int.lbc name exw.exe
	wrc -q -ad exw.res exw.exe

exwc.exe : interpreter_objects 
	wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\int.lbc name exwc.exe
	wrc -q -ad exw.res exwc.exe

svn_rev : .SYMBOLIC
	$(EX) revget.ex

interpreter : .SYMBOLIC builddirs 
        wmake -f makefile.wat exw.exe EX=exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat exwc.exe EX=exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

install-generic : .SYMBOLIC
	@for %i in (*.e) do @copy %i $(PREFIX)\source\
	@for %i in (*.ex) do @copy %i $(PREFIX)\source\
	@copy ..\include\* $(PREFIX)\include\
	
installwin : .SYMBOLIC install-generic
	@copy ecw.exe $(PREFIX)\bin\
	@copy exw.exe $(PREFIX)\bin\
	@copy exwc.exe $(PREFIX)\bin\
	@copy backendw.exe $(PREFIX)\bin\
	@copy backendc.exe $(PREFIX)\bin\
	@copy ecw.lib $(PREFIX)\bin\

installdos : .SYMBOLIC install-generic
	@copy ec.exe $(PREFIX)\bin\
	@copy backendd.exe $(%PREFIX)\bin\
	@copy ec.lib $(PREFIX)\bin\
	
install : .SYMBOLIC installwin installdos
	
	
ecw.exe : rev.e $(OBJDIR)\ec.c pcre $(PCRE_OBJECTS) $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ec.lbc
	@%append .\$(OBJDIR)\ec.lbc option quiet
	@%append .\$(OBJDIR)\ec.lbc option caseexact
	@for %i in ($(PCRE_OBJECTS) $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ec.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\ec.lbc name ecw.exe
	wrc -q -ad exw.res ecw.exe


translator : .SYMBOLIC builddirs
	wmake -f makefile.wat ecw.exe EX=exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dostranslator : .SYMBOLIC builddirs
	wmake -f makefile.wat ec.exe EX=ex.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

backendw.exe : backendflag rev.e $(OBJDIR)\backend.c pcre $(PCRE_OBJECTS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- BACKEND WIN -----------
	@%create .\$(OBJDIR)\exwb.lbc
	@%append .\$(OBJDIR)\exwb.lbc option quiet
	@%append .\$(OBJDIR)\exwb.lbc option caseexact
	@for %i in ($(PCRE_OBJECTS) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\exwb.lbc file %i
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendw.exe
	wrc -q -ad exw.res backendw.exe
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendc.exe
	wrc -q -ad exw.res backendc.exe


backend : .SYMBOLIC builddirs
    @echo ------- BACKEND -----------
        wmake -f makefile.wat backendw.exe EX=exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dosbackend : .SYMBOLIC builddirs
        wmake -f makefile.wat backendd.exe EX=ex.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

dos : .SYMBOLIC builddirs
	wmake -f makefile.wat ex.exe EX=ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

doseubin : .SYMBOLIC builddirs
	wmake -f makefile.wat ex.exe EX=exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS"

backendd.exe : backendflag rev.e $(OBJDIR)\backend.c pcre $(PCRE_OBJECTS) $(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\exb.lbc
	@%append .\$(OBJDIR)\exb.lbc option quiet
	@%append .\$(OBJDIR)\exb.lbc option caseexact
	@%append .\$(OBJDIR)\exb.lbc option osname='CauseWay'
	@%append .\$(OBJDIR)\exb.lbc libpath $(%WATCOM)\lib386
	@%append .\$(OBJDIR)\exb.lbc libpath $(%WATCOM)\lib386\dos
	@%append .\$(OBJDIR)\exb.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append .\$(OBJDIR)\exb.lbc format os2 le ^
	@%append .\$(OBJDIR)\exb.lbc OPTION STACK=262144
	@%append .\$(OBJDIR)\exb.lbc OPTION QUIET
	@%append .\$(OBJDIR)\exb.lbc OPTION ELIMINATE
	@%append .\$(OBJDIR)\exb.lbc OPTION CASEEXACT
	@for %i in ($(PCRE_OBJECTS) $(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\exb.lbc file %i
	wlink  $(DEBUGLINK) @.\$(OBJDIR)\exb.lbc name backendd.exe
	le23p backendd.exe
	cwc backendd.exe

ex.exe : rev.e $(OBJDIR)\int.c pcre $(PCRE_OBJECTS) $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ex.lbc
	@%append .\$(OBJDIR)\ex.lbc option quiet
	@%append .\$(OBJDIR)\ex.lbc option caseexact
	@%append .\$(OBJDIR)\ex.lbc option osname='CauseWay'
	@%append .\$(OBJDIR)\ex.lbc libpath $(%WATCOM)\lib386
	@%append .\$(OBJDIR)\ex.lbc libpath $(%WATCOM)\lib386\dos
	@%append .\$(OBJDIR)\ex.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append .\$(OBJDIR)\ex.lbc format os2 le ^
	@%append .\$(OBJDIR)\ex.lbc OPTION STACK=262144
	@%append .\$(OBJDIR)\ex.lbc OPTION QUIET
	@%append .\$(OBJDIR)\ex.lbc OPTION ELIMINATE
	@%append .\$(OBJDIR)\ex.lbc OPTION CASEEXACT
	@for %i in ($(PCRE_OBJECTS) $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ex.lbc file %i
	wlink  $(DEBUGLINK) @.\$(OBJDIR)\ex.lbc name ex.exe
	le23p ex.exe
	cwc ex.exe

ec.exe : rev.e $(OBJDIR)\ec.c pcre $(PCRE_OBJECTS) $(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ec.lbc
	@%append .\$(OBJDIR)\ec.lbc option quiet
	@%append .\$(OBJDIR)\ec.lbc option caseexact
	@%append .\$(OBJDIR)\ec.lbc option osname='CauseWay'
	@%append .\$(OBJDIR)\ec.lbc libpath $(%WATCOM)\lib386
	@%append .\$(OBJDIR)\ec.lbc libpath $(%WATCOM)\lib386\dos
	@%append .\$(OBJDIR)\ec.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append .\$(OBJDIR)\ec.lbc format os2 le ^
	@%append .\$(OBJDIR)\ec.lbc OPTION STACK=262144
	@%append .\$(OBJDIR)\ec.lbc OPTION QUIET
	@%append .\$(OBJDIR)\ec.lbc OPTION ELIMINATE
	@%append .\$(OBJDIR)\ec.lbc OPTION CASEEXACT
	@for %i in ($(PCRE_OBJECTS) $(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ec.lbc file %i
	wlink $(DEBUGLINK) @.\$(OBJDIR)\ec.lbc name ec.exe
	le23p ec.exe
	cwc ec.exe

.\intobj\main-.c: $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
.\transobj\main-.c: $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
.\backobj\main-.c: $(EU_CORE_FILES) backend.ex
.\dosobj\main-.c: $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
.\dostrobj\main-.c: $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES)
.\dosbkobj\main-.c: $(EU_CORE_FILES) backend.ex

rev.e :
	$(EX) revget.ex

.\$(OBJDIR)\main-.c : $(EU_TARGET)ex
	cd .\$(OBJDIR)
	$(EXE) $(INCDIR) ..\ec.ex $(DOSEUBIN) $(INCDIR) ..\$(EU_TARGET)ex
	-if exist scientific.c copy scientific.c scientif.c
	cd ..

$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex
	cd .\$(OBJDIR)
	$(EXE) $(INCDIR) ..\ec.ex $(DOSEUBIN) $(INCDIR) ..\$(EU_TARGET)ex
	-if exist scientific.c copy scientific.c scientif.c
	cd ..

.\$(OBJDIR)\int.obj :  .\$(OBJDIR)\int.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\main-.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\main-0.obj : $(OBJDIR)\main-0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\cominit.obj : $(OBJDIR)\cominit.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\intinit.obj : $(OBJDIR)\intinit.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\mode.obj : $(OBJDIR)\mode.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@
	
.\$(OBJDIR)\global.obj :.\$(OBJDIR)\global.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\pathopen.obj :  .MULTIPLE $(OBJDIR)\pathopen.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\init-.obj :  .MULTIPLE ./$(OBJDIR)\init-.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\io.obj :  .MULTIPLE ./$(OBJDIR)\io.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\filesys.obj : .\$(OBJDIR)\filesys.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$@


.\$(OBJDIR)\error.obj :  .MULTIPLE $(OBJDIR)\error.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\machine.obj :  .MULTIPLE ./$(OBJDIR)/machine.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\symtab.obj :  .MULTIPLE ./$(OBJDIR)\symtab.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\symtab_0.obj :  .MULTIPLE ./$(OBJDIR)\symtab.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\0rror.obj :  .MULTIPLE ./$(OBJDIR)\0rror.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scanner.obj :  .MULTIPLE ./$(OBJDIR)\scanner.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scanne_0.obj :  .MULTIPLE $(OBJDIR)\scanne_0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scientific.obj :  .MULTIPLE ./$(OBJDIR)\scientific.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\scientif.obj :  .MULTIPLE ./$(OBJDIR)\scientif.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\main.obj :  .MULTIPLE ./$(OBJDIR)\main.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit.obj :  .MULTIPLE ./$(OBJDIR)\emit.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit_0.obj :  .MULTIPLE ./$(OBJDIR)\emit_0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\emit_1.obj :  .MULTIPLE ./$(OBJDIR)\emit_1.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser.obj :  .MULTIPLE ./$(OBJDIR)\parser.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_0.obj :  .MULTIPLE ./$(OBJDIR)\parser_0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_1.obj :  .MULTIPLE ./$(OBJDIR)\parser_1.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_2.obj :  .MULTIPLE ./$(OBJDIR)\parser_2.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\parser_3.obj :  .MULTIPLE ./$(OBJDIR)\parser_3.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\0ackend.obj :  .MULTIPLE ./$(OBJDIR)\0ackend.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\backend.obj :  .MULTIPLE ./$(OBJDIR)\backend.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compress.obj :  .MULTIPLE ./$(OBJDIR)\compress.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_out.obj :  .MULTIPLE ./$(OBJDIR)\c_out.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\ec.obj :  .MULTIPLE ./ec.ex $(OBJDIR)\ec.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_decl.obj :  .MULTIPLE ./$(OBJDIR)\c_decl.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_dec0.obj :  .MULTIPLE ./$(OBJDIR)\c_dec0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\c_dec1.obj :  .MULTIPLE ./$(OBJDIR)\c_dec1.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compile.obj :  .MULTIPLE ./$(OBJDIR)\compile.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_0.obj :  .MULTIPLE ./$(OBJDIR)\compil_0.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_1.obj :  .MULTIPLE ./$(OBJDIR)\compil_1.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_2.obj :  .MULTIPLE ./$(OBJDIR)\compil_2.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_3.obj :  .MULTIPLE ./$(OBJDIR)\compil_3.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_4.obj :  ./$(OBJDIR)\compil_4.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_5.obj :  ./$(OBJDIR)\compil_5.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_6.obj :  ./$(OBJDIR)\compil_6.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_7.obj :  ./$(OBJDIR)\compil_7.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_8.obj :  ./$(OBJDIR)\compil_8.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_9.obj :  ./$(OBJDIR)\compil_9.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\compil_A.obj :  ./$(OBJDIR)\compil_A.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\traninit.obj :  ./$(OBJDIR)\traninit.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\tranplat.obj :  ./$(OBJDIR)\tranplat.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\get.obj :  .\$(OBJDIR)\main-.c 
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\sort.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\wildcard.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\sequence.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\text.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\search.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\string.obj :  .\$(OBJDIR)\main-.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$^@

.\$(OBJDIR)\math.obj : .\$(OBJDIR)\math.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$@

.\$(OBJDIR)\os.obj : .\$(OBJDIR)\os.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$@

.\$(OBJDIR)\types.obj : .\$(OBJDIR)\types.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$@

.\$(OBJDIR)\dll.obj : .\$(OBJDIR)\dll.c
	$(CC) $(FE_FLAGS) $^*.c -fo=$@

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

.\$(OBJDIR)\back\be_pcre.obj : ./be_pcre.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $(PCRE_FLAGS) /I.\pcre $^&.c -fo=$^@

.\$(OBJDIR)\back\be_runtime.obj : ./be_runtime.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_symtab.obj : ./be_symtab.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_w.obj : ./be_w.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

.\$(OBJDIR)\back\be_decompress.obj : ./be_decompress.c
	$(CC) $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@
	
.\pcre\pcre_chartables.obj : .\pcre\pcre_chartables.c.win
	-copy .\pcre\pcre_chartables.c.win .\pcre\pcre_chartables.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_compile.obj : .\pcre\pcre_compile.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_config.obj : .\pcre\pcre_config.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_dfa_exec.obj : .\pcre\pcre_dfa_exec.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_exec.obj : .\pcre\pcre_exec.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_fullinfo.obj : .\pcre\pcre_fullinfo.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_get.obj : .\pcre\pcre_get.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_globals.obj : .\pcre\pcre_globals.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_info.obj : .\pcre\pcre_info.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_maketables.obj : .\pcre\pcre_maketables.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_newline.obj : .\pcre\pcre_newline.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_ord2utf8.obj : .\pcre\pcre_ord2utf8.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_refcount.obj : .\pcre\pcre_refcount.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_study.obj : .\pcre\pcre_study.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_tables.obj : .\pcre\pcre_tables.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_try_flipped.obj : .\pcre\pcre_try_flipped.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_ucp_searchfuncs.obj : .\pcre\pcre_ucp_searchfuncs.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_valid_utf8.obj : .\pcre\pcre_valid_utf8.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_version.obj : .\pcre\pcre_version.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre_xclass.obj : .\pcre\pcre_xclass.c
	$(CC) $(PCRE_FLAGS) $^*.c -fo=$^@

.\pcre\pcre.h : .\pcre\pcre.h.win
	-copy .\pcre\pcre.h.win .\pcre\pcre.h

.\pcre\config.h : .\pcre\config.h.win
	-copy .\pcre\config.h.win .\pcre\config.h

