# OpenWatcom makefile for Euphoria (Win32/DOS32)
#
# You must first run configure.bat, supplying any options you might need:
#
#     --without-euphoria      Use this option if you are building Euphoria 
#		     with only a C compiler.
# 
#     --prefix <dir>  Use this option to specify the location for euphoria to
#		     be installed.  The default is EUDIR, or c:\euphoria,
#		     if EUDIR is not set.
#
#     --eubin <dir>   Use this option to specify the location of the interpreter
#		     binary to use to translate the front end.  The default
#		     is ..\bin
#
#     --managed-mem   Use this option to turn EUPHORIA's memory cache on in
#		     the targets
#
#     --debug	 Use this option to turn on debugging symbols
#
#
#     --full	  Use this option to so EUPHORIA doesn't report itself
#		     as a development version.
#
# Syntax:
#   Interpreter (euiw.exe, eui.exe):  wmake interpreter
#   Translator  		  (euc.exe):  wmake translator
#   Translator Library     (eu.lib):  wmake library
#   Backend 	 eub.exe, eubw.exe):  wmake backend
#	        	   Make all targets:  wmake
#		             	    		  wmake all
#           Make all Win32 Binaries:  wmake winall
#
#   Make C sources so this tree      
#   can be built with just a	 
#   compiler.
#   			                   :  wmake translate
#
# Install binaries, source and 
#		    		 include files : wmake install
#
#					 Run unit tests: wmake test
#						Using eu.ex: wmake testeu
#
# The source targets will create a subdirectory called euphoria-r$(SVN_REV). 
# The default for SVN_REV is 'xxx'.
#
#
#   Options:
#		    MANAGED_MEM:  Set this to 1 to use Euphoria's memory cache.
#				  The default is to use straight HeapAlloc/HeapFree calls. ex:
#				      wmake -h interpreter MANAGED_MEM=1
#
#			  DEBUG:  Set this to 1 to build debug versions of the targets.  ex:
#				      wmake -h interpreter DEBUG=1
#
!ifndef CONFIG
CONFIG=config.wat
!endif
!include $(CONFIG)

!ifndef CCOM
CCOM=wat
!endif

!ifndef LIBEXT
LIBEXT=lib
!endif

BASEPATH=$(BUILDDIR)\pcre
!include pcre\objects.wat
!include $(TRUNKDIR)\source\version.mak

FULLBUILDDIR=$(BUILDDIR)

EU_CORE_FILES = &
	block.e &
	common.e &
	emit.e &
	error.e &
	fwdref.e &
	global.e &
	inline.e &
	keylist.e &
	main.e &
	msgtext.e &
	mode.e &
	opnames.e &
	parser.e &
	pathopen.e &
	platform.e &
	preproc.e &
	reswords.e &
	scanner.e &
	scinot.e &
	shift.e &
	symtab.e

EU_INTERPRETER_FILES = &
	$(TRUNKDIR)\include\std\get.e &
	backend.e &
	c_out.e &
	cominit.e &
	compress.e &
	intinit.e &
	int.ex 

EU_TRANSLATOR_FILES = &
	buildsys.e &
	c_decl.e &
	c_out.e &
	cominit.e &
	compile.e &
	compress.e &
	traninit.e &
	ec.ex
	
!include $(BUILDDIR)\transobj.wat
!include $(BUILDDIR)\intobj.wat
!include $(BUILDDIR)\backobj.wat

EU_BACKEND_OBJECTS = &
!ifneq INT_CODES 1
	$(BUILDDIR)\$(OBJDIR)\back\be_magic.obj &
!endif	
	$(BUILDDIR)\$(OBJDIR)\back\be_execute.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_task.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_main.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_alloc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_callc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_rterror.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_syncolor.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_runtime.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_symtab.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_w.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_socket.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_pcre.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_rev.obj &
	$(PCRE_OBJECTS)
#       &
#       $(BUILDDIR)\$(OBJDIR)\memory.obj

EU_LIB_OBJECTS = &
	$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_w.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_alloc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_runtime.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_task.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_callc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_socket.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_pcre.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_rev.obj &
	$(PCRE_OBJECTS)

EU_BACKEND_RUNNER_FILES = &
	.\backend.ex &
	.\compress.e &
	.\reswords.e &
	.\common.e &
	.\cominit.e &
	.\pathopen.e


EU_INCLUDES = $(TRUNKDIR)\include\std\*.e $(TRUNKDIR)\include\*.e &
		$(TRUNKDIR)\include\euphoria\*.e

EU_ALL_FILES = *.e $(EU_INCLUDES) &
		 int.ex ec.ex backend.ex

!ifneq MANAGED_MEM 1
MEMFLAG = /dESIMPLE_MALLOC
!else
MANAGED_FLAG = -D EU_MANAGED_MEM
!endif

!ifeq RELEASE 1
RELEASE_FLAG = -D EU_FULL_RELEASE
!endif

!ifndef EUBIN
EUBIN=$(TRUNKDIR)\bin
!endif

!ifndef PREFIX
!ifneq PREFIX ""
PREFIX=$(%EUDIR)
!else
PREFIX=C:\euphoria
!endif
!endif

!ifndef BUILDDIR
BUILDDIR=.
!endif

!ifeq INT_CODES 1
#TODO hack
MEMFLAG = $(MEMFLAG) /dINT_CODES
!endif

!ifeq DEBUG 1
DEBUGFLAG = /d2 /dEDEBUG 
#DEBUGFLAG = /d2 /dEDEBUG /dDEBUG_OPCODE_TRACE
DEBUGLINK = debug all
TRANSDEBUG= -debug
EUDEBUG=-D DEBUG
!endif

!ifeq HEAP_CHECK 1
HEAPCHECKFLAG=/dHEAP_CHECK
!endif

!ifndef EX
EX=$(EUBIN)\eui.exe
!endif

EXE=$(EX)
INCDIR=-i $(TRUNKDIR)\include

PWD=$(%cdrive):$(%cwd)

VARS=DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
all :  .SYMBOLIC
    @echo ------- ALL -----------
	wmake -h interpreter $(VARS)
	wmake -h translator $(VARS)
	wmake -h winlibrary $(VARS)
	wmake -h backend $(VARS)
# TODO: remove	wmake -h winall $(VARS)

BUILD_DIRS=$(BUILDDIR)\intobj $(BUILDDIR)\transobj $(BUILDDIR)\WINlibobj $(BUILDDIR)\backobj

distclean : .SYMBOLIC clean
!ifndef RM
	@ECHO Please run configure
	error
!endif
	cd pcre
	wmake -f makefile.wat CONFIG=..\$(CONFIG) distclean
	cd ..
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\back\*.*	
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RMDIR) %i\back
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\*.*	
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RMDIR) %i
	-@for %i in ($(BUILD_DIRS)) do -$(RM) %i.wat
	-$(RM) $(CONFIG)
	-$(RM) version.h

clean : .SYMBOLIC pcre
!ifndef DELTREE
	@ECHO Please run configure
	error
!endif
	-$(RM) &
	$(BUILDDIR)\euiw.exe $(BUILDDIR)\eui.exe $(BUILDDIR)\euc.exe $(BUILDDIR)\eu.lib $(BUILDDIR)\eubw.exe $(BUILDDIR)\eub.exe $(BUILDDIR)\main-.h $(BUILDDIR)\*.sym
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\back\*.obj
	-@for %i in ($(BUILDDIR)\libobj $(BUILDDIR)\winlibobj do -$(RMDIR) %i\back
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\*.*
	-@for %i in ($(BUILDDIR)\libobj $(BUILDDIR)\winlibobj do -$(RMDIR) %i
	cd pcre
	-wmake -f makefile.wat CONFIG=..\$(CONFIG) clean
	cd ..

$(BUILD_DIRS) : .existsonly
	mkdir $@
	mkdir $@\back

OS=WIN
OSFLAG=EWINDOWS
LIBTARGET=$(BUILDDIR)\eu.lib

CC = wcc386
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG) $(HEAPCHECKFLAG) /I..\
BE_FLAGS = /ol /zp4 /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(%EBACKEND) $(MEMFLAG) $(DEBUGFLAG) $(HEAPCHECKFLAG)
	
library : .SYMBOLIC version.h runtime
    @echo ------- LIBRARY -----------
	wmake -h $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj $(VARS) MANAGED_MEM=$(MANAGED_MEM)

winlibrary : .SYMBOLIC
    @echo ------- WINDOWS LIBRARY -----------
	wmake -h OS=WIN library  $(VARS)

runtime: .SYMBOLIC 
    @echo ------- RUNTIME -----------
	set ERUNTIME=/dERUNTIME

backendflag: .SYMBOLIC
	set EBACKEND=/dBACKEND

$(BUILDDIR)\eu.lib : $(BUILDDIR)\$(OBJDIR)\back $(EU_LIB_OBJECTS)
	wlib -q $(BUILDDIR)\eu.lib $(EU_LIB_OBJECTS)

!ifdef OBJDIR

objlist : .SYMBOLIC
	wmake -h $(VARS) OS=$(OS) EU_NAME_OBJECT=$(EU_NAME_OBJECT) OBJDIR=$(OBJDIR) $(BUILDDIR)\$(OBJDIR).wat EX=$(EUBIN)\eui.exe
    
$(BUILDDIR)\$(OBJDIR)\back : .EXISTSONLY $(BUILDDIR)\$(OBJDIR)
    -mkdir $(BUILDDIR)\$(OBJDIR)\back

$(BUILDDIR)\$(OBJDIR).wat : $(BUILDDIR)\$(OBJDIR)\main-.c &
!ifneq INT_CODES 1
$(BUILDDIR)\$(OBJDIR)\back\be_magic.c
!else

!endif
	@if exist $(BUILDDIR)\objtmp rmdir /Q /S $(BUILDDIR)\objtmp
	@mkdir $(BUILDDIR)\objtmp
	@copy $(BUILDDIR)\$(OBJDIR)\*.c $(BUILDDIR)\objtmp
	@cd $(BUILDDIR)\objtmp
	ren *.c *.obj
	%create $(OBJDIR).wat
	%append $(OBJDIR).wat $(EU_NAME_OBJECT) = &  
	for %i in (*.obj) do @%append $(OBJDIR).wat $(BUILDDIR)\$(OBJDIR)\%i & 
	%append $(OBJDIR).wat    
	del *.obj
	cd $(TRUNKDIR)\source
	move $(BUILDDIR)\objtmp\$(OBJDIR).wat $(BUILDDIR)
	rmdir $(BUILDDIR)\objtmp


exwsource : .SYMBOLIC version.h $(BUILDDIR)\$(OBJDIR)\main-.c
ecwsource : .SYMBOLIC version.h $(BUILDDIR)\$(OBJDIR)\main-.c
backendsource : .SYMBOLIC version.h $(BUILDDIR)\$(OBJDIR)\main-.c
ecsource : .SYMBOLIC version.h $(BUILDDIR)\$(OBJDIR)\main-.c
exsource : .SYMBOLIC version.h $(BUILDDIR)\$(OBJDIR)\main-.c

!endif
# OBJDIR

!ifdef EUPHORIA
translate : .SYMBOLIC  
    @echo ------- TRANSLATE WIN -----------
	$wmake -h exwsource EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h ecwsource EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h backendsource EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)

testeu : .SYMBOLIC
	cd ..\tests
	set EUCOMPILEDIR=$(TRUNKDIR)
	$(EXE) ..\source\eutest.ex -i ..\include -exe "$(FULLBUILDDIR)\eui.exe -batch $(TRUNKDIR)\source\eu.ex"
	cd ..\source

!endif #EUPHORIA

test : .SYMBOLIC
	cd ..\tests
	set EUCOMPILEDIR=$(TRUNKDIR) 
	$(EXE) ..\source\eutest.ex -i ..\include -cc wat -exe $(FULLBUILDDIR)\eui.exe -ec $(FULLBUILDDIR)\euc.exe -lib   $(FULLBUILDDIR)\eu.$(LIBEXT)
	cd ..\source
	

!ifdef BUILD_TOOLS
$(BUILDDIR)\eutest.exe: $(BUILDDIR)\eutestdr\main-.c $(BUILDDIR)\eutestdr.wat $(BUILDDIR)\eu.lib $(BUILDDIR)\eutestdr
	@%create $(BUILDDIR)\eutestdr\eutestdr.lbc
	@%append $(BUILDDIR)\eutestdr\eutestdr.lbc option quiet
	@%append $(BUILDDIR)\eutestdr\eutestdr.lbc option caseexact
	@%append $(BUILDDIR)\eutestdr\eutestdr.lbc library ws2_32
	@for %i in ($(EUTEST_OBJECTS)) do @%append $(BUILDDIR)\eutestdr\eutest.lbc file %i
	wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\eutestdr\eutestdr.lbc name $(BUILDDIR)\eutest.exe

$(BUILDDIR)\eutestdr.wat : $(BUILDDIR)\eutestdr\main-.c
	@if exist $(BUILDDIR)\objtmp rmdir /Q /S $(BUILDDIR)\objtmp
	@mkdir $(BUILDDIR)\objtmp
	@copy $(BUILDDIR)\eutestdr\*.c $(BUILDDIR)\objtmp
	@cd $(BUILDDIR)\objtmp
	ren *.c *.obj
	%create eutestdr.wat
	%append eutestdr.wat $(EU_NAME_OBJECT) = &  
	for %i in (*.obj) do @%append eutestdr.wat $(BUILDDIR)\eutestdr\%i & 
	%append eutestdr.wat    
	del *.obj
	cd $(TRUNKDIR)\source
	move $(BUILDDIR)\objtmp\eutestdr.wat $(BUILDDIR)
	rmdir $(BUILDDIR)\objtmp


$(BUILDDIR)\eutestdr\main-.c : $(TRUNKDIR)\source\eutest.ex $(BUILDDIR)\eutestdr
	-$(RM) $(BUILDDIR)\eutestdr\*.*
	cd  $(BUILDDIR)\eutestdr
	$(EXE) $(INCDIR) $(EUDEBUG) $(TRUNKDIR)\source\ec.ex -nobuild -wat -plat $(TRANSDEBUG) $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\eutest.ex
	cd $(TRUNKDIR)\source

$(BUILDDIR)\eutestdr :
	mkdir $(BUILDDIR)\eutestdr

!endif #BUILD_TOOLS

$(BUILDDIR)\eui.exe $(BUILDDIR)\euiw.exe: $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) 
	@%create $(BUILDDIR)\$(OBJDIR)\euiw.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc library ws2_32
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc file %i
	wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euiw.lbc name $(BUILDDIR)\eui.exe
	wrc -q -ad exw.res $(BUILDDIR)\eui.exe
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euiw.lbc name $(BUILDDIR)\euiw.exe
	wrc -q -ad exw.res $(BUILDDIR)\euiw.exe

interpreter : .SYMBOLIC version.h
	wmake -h $(BUILDDIR)\intobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=intobj $(VARS) EU_NAME_OBJECT=EU_INTERPRETER_OBJECTS
	wmake -h $(BUILDDIR)\euiw.exe EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h $(BUILDDIR)\eui.exe EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

install : .SYMBOLIC
	@echo --------- install $(PREFIX) ------------
	if /I $(PWD)==$(PREFIX)\source exit
	for %i in (*.e) do @copy %i $(PREFIX)\source\
	for %i in (*.ex) do @copy %i $(PREFIX)\source\
	if not exist $(PREFIX)\include\std mkdir $(PREFIX)\include\std
	copy ..\include\* $(PREFIX)\include\
	copy ..\include\std\* $(PREFIX)\include\std
	if not exist $(PREFIX)\include\std\net mkdir $(PREFIX)\include\std\net
	copy ..\include\std\net\* $(PREFIX)\include\std\net
	if not exist $(PREFIX)\include\std\win32 mkdir $(PREFIX)\include\std\win32
	copy ..\include\std\win32\* $(PREFIX)\include\std\win32
	if not exist $(PREFIX)\include\std\unix mkdir $(PREFIX)\include\std\unix
	copy ..\include\std\unix\* $(PREFIX)\include\std\unix
	if not exist $(PREFIX)\include\euphoria mkdir $(PREFIX)\include\euphoria
	copy ..\include\euphoria\* $(PREFIX)\include\euphoria
	@if exist $(BUILDDIR)\euc.exe copy $(BUILDDIR)\euc.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\euiw.exe copy $(BUILDDIR)\euiw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eui.exe copy $(BUILDDIR)\eui.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eubw.exe copy $(BUILDDIR)\eubw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eub.exe copy $(BUILDDIR)\eub.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eu.lib copy $(BUILDDIR)\eu.lib $(PREFIX)\bin\	

installbin : .SYMBOLIC
	@if exist $(BUILDDIR)\euc.exe copy $(BUILDDIR)\euc.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\euiw.exe copy $(BUILDDIR)\euiw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eui.exe copy $(BUILDDIR)\eui.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eubw.exe copy $(BUILDDIR)\eubw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eub.exe copy $(BUILDDIR)\eub.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eu.lib copy $(BUILDDIR)\eu.lib $(PREFIX)\bin\	
	
$(BUILDDIR)\euc.exe : $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create $(BUILDDIR)\$(OBJDIR)\euc.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\euc.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\euc.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\euc.lbc library ws2_32
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\euc.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euc.lbc name $(BUILDDIR)\euc.exe
	wrc -q -ad exw.res $(BUILDDIR)\euc.exe


translator : .SYMBOLIC version.h
    @echo ------- TRANSLATOR -----------
	wmake -h $(BUILDDIR)\transobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj  $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=transobj EU_NAME_OBJECT=EU_TRANSLATOR_OBJECTS $(VARS)
	wmake -h $(BUILDDIR)\euc.exe EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

$(BUILDDIR)\eubw.exe :  $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- BACKEND WIN -----------
	@%create $(BUILDDIR)\$(OBJDIR)\eub.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\eub.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\eub.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\eub.lbc library ws2_32
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\eub.lbc file %i
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\eub.lbc name $(BUILDDIR)\eubw.exe
	wrc -q -ad exw.res $(BUILDDIR)\eubw.exe
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\eub.lbc name $(BUILDDIR)\eub.exe
	wrc -q -ad exw.res $(BUILDDIR)\eub.exe

backend : .SYMBOLIC version.h backendflag
    @echo ------- BACKEND -----------
	wmake -h $(BUILDDIR)\backobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=backobj EU_NAME_OBJECT=EU_BACKEND_RUNNER_OBJECTS $(VARS)
	wmake -h $(BUILDDIR)\eubw.exe EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

$(BUILDDIR)\intobj\main-.c: $(BUILDDIR)\intobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\transobj\main-.c: $(BUILDDIR)\transobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES)
$(BUILDDIR)\backobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES)

!ifdef EUPHORIA
# We should have ifdef EUPHORIA so that make doesn't decide
# to update rev.e when there is no $(EX)
be_rev.c : .recheck .always
	$(EX) -i ..\include revget.ex

!ifdef EU_TARGET
!ifdef OBJDIR
$(BUILDDIR)\$(OBJDIR)\main-.c : $(EU_TARGET)ex $(BUILDDIR)\$(OBJDIR)\back $(EU_TRANSLATOR_FILES)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\back\*.*
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	cd  $(BUILDDIR)\$(OBJDIR)
	$(EXE) $(INCDIR) $(EUDEBUG) $(TRUNKDIR)\source\ec.ex $(TRANSDEBUG) -nobuild -wat -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\$(EU_TARGET)ex
	cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex  $(BUILDDIR)\$(OBJDIR)\back $(EU_TRANSLATOR_FILES)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\back\*.*
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	cd $(BUILDDIR)\$(OBJDIR)
	$(EXE) $(INCDIR) $(EUDEBUG) $(TRUNKDIR)\source\ec.ex  $(TRANSDEBUG) -nobuild -wat -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\$(EU_TARGET)ex
	cd $(TRUNKDIR)\source
!endif
!endif
!else
$(BUILDDIR)\$(OBJDIR)\main-.c $(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex $(BUILDDIR)\$(OBJDIR)\back
	@echo *****************************************************************
	@echo If you have EUPHORIA installed you'll need to run configure again.
	@echo Make is configured to not try to use the interpreter.
	@echo *****************************************************************

!endif

.c: $(BUILDDIR)\$(OBJDIR);$(BUILDDIR)\$(OBJDIR)\back
.c.obj: 
	$(CC) $(FE_FLAGS) $(BE_FLAGS) $[@ -fo=$^@
	
$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj : ./be_inline.c $(BUILDDIR)\$(OBJDIR)\back
	$(CC) /oe=40 $(BE_FLAGS) $(FE_FLAGS) $^&.c -fo=$^@

!ifneq INT_CODES 1
$(BUILDDIR)\$(OBJDIR)\back\be_magic.c :  $(BUILDDIR)\$(OBJDIR)\back\be_execute.obj $(TRUNKDIR)\source\findjmp.ex
	cd $(BUILDDIR)\$(OBJDIR)\back
	$(EXE) $(INCDIR) $(TRUNKDIR)\source\findjmp.ex
	cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\back\be_magic.obj : $(BUILDDIR)\$(OBJDIR)\back\be_magic.c
	$(CC) $(FE_FLAGS) $(BE_FLAGS) $[@ -fo=$^@
!endif

$(BUILDDIR)\$(OBJDIR)\back\be_execute.obj : be_execute.c *.h $(CONFIG)
$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj : be_decompress.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_task.obj : be_task.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_main.obj : be_main.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_alloc.obj : be_alloc.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_callc.obj : be_callc.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj : be_inline.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj : be_machine.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_rterror.obj : be_rterror.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_syncolor.obj : be_syncolor.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_runtime.obj : be_runtime.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_symtab.obj : be_symtab.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_w.obj : be_w.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_socket.obj : be_socket.c *.h $(CONFIG)
$(BUILDDIR)\$(OBJDIR)\back\be_pcre.obj : be_pcre.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_rev.obj : be_rev.c *.h $(CONFIG) 

version.h: version.mak
    @echo ------- VERSION.H -----------
	@echo // DO NOT EDIT, EDIT version.mak INSTEAD > version.h
	@echo $#define MAJ_VER $(MAJ_VER) >> version.h
	@echo $#define MIN_VER $(MIN_VER) >> version.h
	@echo $#define PAT_VER $(PAT_VER) >> version.h
	@echo $#define REL_TYPE "$(REL_TYPE)" >> version.h

!ifdef PCRE_OBJECTS	
$(PCRE_OBJECTS) : pcre/*.c pcre/pcre.h.windows pcre/config.h.windows
    @echo ------- REG EXP -----------
	cd pcre
	wmake -h -f makefile.wat CONFIG=..\$(CONFIG) EOSTYPE=-D$(OSFLAG)
	cd ..
!endif
