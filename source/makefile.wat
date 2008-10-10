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
#     --eubin <dir>   Use this option to specify the location of the interpreter
#                     binary to use to translate the front end.  The default
#                     is ..\bin
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
	scinot.e &
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
	..\include\std\get.e &
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
	
!include transobj.wat
!include intobj.wat
!include backobj.wat
!include dosobj.wat
!include dostrobj.wat
!include dosbkobj.wat

EU_BACKEND_OBJECTS = &
	.\$(OBJDIR)\back\be_execute.obj &
	.\$(OBJDIR)\back\be_decompress.obj &
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
	.\$(OBJDIR)\back\be_w.obj &
	.\$(OBJDIR)\back\be_regex.obj &
	.\$(OBJDIR)\back\regex.obj 
#	&
#	.\$(OBJDIR)\memory.obj

EU_LIB_OBJECTS = &
	.\$(OBJDIR)\back\be_decompress.obj &
	.\$(OBJDIR)\back\be_machine.obj &
	.\$(OBJDIR)\back\be_w.obj &
	.\$(OBJDIR)\back\be_alloc.obj &
	.\$(OBJDIR)\back\be_inline.obj &
	.\$(OBJDIR)\back\be_runtime.obj &
	.\$(OBJDIR)\back\be_task.obj &
	.\$(OBJDIR)\back\be_callc.obj &
	.\$(OBJDIR)\back\be_regex.obj &
	.\$(OBJDIR)\back\regex.obj

EU_BACKEND_RUNNER_FILES = &
	.\$(OBJDIR)\backend.ex &
	.\$(OBJDIR)\wildcard.e &
	.\$(OBJDIR)\compress.e


!ifneq MANAGED_MEM 1
MEMFLAG = /dESIMPLE_MALLOC
!endif

!ifndef EUBIN
EUBIN=..\bin
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

BUILD_DIRS=intobj transobj libobj backobj dosbkobj doslibobj dosobj dostrobj

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
		intobj\* transobj\* libobj\* backobj\* dosobj\* doslibobj\* dosbkobj\* dostrobj\*
	-if exist $(%WINDIR)\command\deltree.exe deltree /y &
		ex.exe ec.exe exw.exe exwc.exe ecw.exe ec.lib ecw.lib backendw.exe backendc.exe backendd.exe main-.h
	-if exist $(%WINDIR)\command\deltree.exe deltree /y &
		intobj\* transobj\* libobj\* backobj\* dosobj\* doslibobj\* dosbkobj\* dostrobj\*

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

ecw.lib : runtime $(EU_LIB_OBJECTS)
	wlib -q ecw.lib $(EU_LIB_OBJECTS)

ec.lib : runtime $(EU_LIB_OBJECTS)
	wlib -q ec.lib $(EU_LIB_OBJECTS)
	
interpreter_objects : .SYMBOLIC svn_rev $(OBJDIR)\int.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\int.lbc
	@%append .\$(OBJDIR)\int.lbc option quiet
	@%append .\$(OBJDIR)\int.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\int.lbc file %i

objlist : .SYMBOLIC
	@if exist objtmp rmdir /Q /S objtmp
	@mkdir objtmp
	@copy $(OBJDIR)\*.c objtmp
	@cd objtmp
	@ren *.c *.obj
	@cd ..
	@%create $(OBJDIR).wat
	@%append $(OBJDIR).wat $(EU_NAME_OBJECT) = &  
	@cd objtmp
	@for %i in (*.obj) do @%append ..\$(OBJDIR).wat .\$(OBJDIR)\%i &  
	@del *.obj
	@cd ..
	@rmdir objtmp
	@%append $(OBJDIR).wat   

exwsource : .SYMBOLIC .\$(OBJDIR)/main-.c
ecwsource : .SYMBOLIC .\$(OBJDIR)/main-.c
backendsource : .SYMBOLIC .\$(OBJDIR)/main-.c
ecsource : .SYMBOLIC .\$(OBJDIR)/main-.c
exsource : .SYMBOLIC .\$(OBJDIR)/main-.c

translate-win : .SYMBOLIC  builddirs
    @echo ------- TRANSLATE WIN -----------
        wmake -f makefile.wat exwsource EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat ecwsource EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat backendsource EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	
translate-dos : .SYMBOLIC builddirs
    @echo ------- TRANSLATE DOS -----------
	wmake -f makefile.wat exsource EX=$(EUBIN)\ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -f makefile.wat ecsource EX=$(EUBIN)\ex.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
        wmake -f makefile.wat backendsource EX=$(EUBIN)\ex.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	
translate : .SYMBOLIC translate-win translate-dos
	
SVN_REV=xxx
SOURCEDIR= euphoria-r$(SVN_REV)

common-source : .SYMBOLIC
	if exist $(SOURCEDIR) rmdir /Q /S $(SOURCEDIR)
	mkdir $(SOURCEDIR)
	copy configure.bat $(SOURCEDIR)
	copy makefile.wat $(SOURCEDIR)
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
	$(EX) -i ..\include revget.ex

interpreter : .SYMBOLIC builddirs 
        wmake -f makefile.wat .\intobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -f makefile.wat objlist OBJDIR=intobj EU_NAME_OBJECT=EU_INTERPRETER_OBJECTS
        wmake -f makefile.wat exw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -f makefile.wat exwc.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

install-generic : .SYMBOLIC
	@for %i in (*.e) do @copy %i $(PREFIX)\source\
	@for %i in (*.ex) do @copy %i $(PREFIX)\source\
	@copy ..\include\* $(PREFIX)\include\
	@if not exist $(PREFIX)\include\std mkdir $(PREFIX)\include\std
	@copy ..\include\std\* $(PREFIX)\include\std
	@if not exist $(PREFIX)\include\euphoria mkdir $(PREFIX)\include\euphoria
	@copy ..\include\euphoria\* $(PREFIX)\include\euphoria
	
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
	
	
ecw.exe : svn_rev $(OBJDIR)\ec.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create .\$(OBJDIR)\ec.lbc
	@%append .\$(OBJDIR)\ec.lbc option quiet
	@%append .\$(OBJDIR)\ec.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ec.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\ec.lbc name ecw.exe
	wrc -q -ad exw.res ecw.exe


translator : .SYMBOLIC builddirs
        wmake -f makefile.wat .\transobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -f makefile.wat objlist OBJDIR=transobj EU_NAME_OBJECT=EU_TRANSLATOR_OBJECTS
	wmake -f makefile.wat ecw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dostranslator : .SYMBOLIC builddirs
	wmake -f makefile.wat .\dostrobj\main-.c EX=$(EUBIN)\ex.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -f makefile.wat objlist OBJDIR=dostrobj EU_NAME_OBJECT=EU_TRANSDOS_OBJECTS
	wmake -f makefile.wat ec.exe EX=$(EUBIN)\ex.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

backendw.exe : backendflag svn_rev $(OBJDIR)\backend.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- BACKEND WIN -----------
	@%create .\$(OBJDIR)\exwb.lbc
	@%append .\$(OBJDIR)\exwb.lbc option quiet
	@%append .\$(OBJDIR)\exwb.lbc option caseexact
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\exwb.lbc file %i
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendw.exe
	wrc -q -ad exw.res backendw.exe
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @.\$(OBJDIR)\exwb.lbc name backendc.exe
	wrc -q -ad exw.res backendc.exe


backend : .SYMBOLIC builddirs
    @echo ------- BACKEND -----------
        wmake -f makefile.wat .\backobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -f makefile.wat objlist OBJDIR=backobj EU_NAME_OBJECT=EU_BACKEND_RUNNER_OBJECTS
        wmake -f makefile.wat backendw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dosbackend : .SYMBOLIC builddirs
    @echo ------- BACKEND -----------
        wmake -f makefile.wat .\dosbkobj\main-.c EX=$(EUBIN)\ex.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -f makefile.wat objlist OBJDIR=dosbkobj EU_NAME_OBJECT=EU_DOSBACKEND_RUNNER_OBJECTS
        wmake -f makefile.wat backendd.exe EX=$(EUBIN)\ex.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

dos : .SYMBOLIC builddirs
	wmake -f makefile.wat .\dosobj\main-.c EX=$(EUBIN)\ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS
	wmake -f makefile.wat ex.exe EX=$(EUBIN)\ex.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

doseubin : .SYMBOLIC builddirs
	wmake -f makefile.wat .\dosobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS"
	wmake -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS
	wmake -f makefile.wat ex.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS"

backendd.exe : backendflag svn_rev $(OBJDIR)\backend.c $(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
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
	@for %i in ($(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\exb.lbc file %i
	wlink  $(DEBUGLINK) @.\$(OBJDIR)\exb.lbc name backendd.exe
	le23p backendd.exe
	cwc  backendd.exe

ex.exe : svn_rev $(OBJDIR)\int.c $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)
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
	@for %i in ($(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ex.lbc file %i
	wlink  $(DEBUGLINK) @.\$(OBJDIR)\ex.lbc name ex.exe
	le23p ex.exe
	cwc  ex.exe

ec.exe : svn_rev $(OBJDIR)\ec.c $(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)
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
	@for %i in ($(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append .\$(OBJDIR)\ec.lbc file %i
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
	$(EX) -i ..\include revget.ex

.\$(OBJDIR)\main-.c : $(EU_TARGET)ex
	cd .\$(OBJDIR)
	del *.c
	$(EXE) $(INCDIR) ..\ec.ex $(DOSEUBIN) $(INCDIR) ..\$(EU_TARGET)ex
	cd ..

$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex
	cd .\$(OBJDIR)
	del *.c
	$(EXE) $(INCDIR) ..\ec.ex $(DOSEUBIN) $(INCDIR) ..\$(EU_TARGET)ex
	cd ..

.c: $(OBJDIR);$(OBJDIR)\back
.c.obj:
	$(CC) $(FE_FLAGS) $(BE_FLAGS) $[@ -fo=$^@
	
.\$(OBJDIR)\back\be_inline.obj : ./be_inline.c
	$(CC) /oe=40 $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@
