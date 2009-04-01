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
#   Interpreter(exw.exe, exwc.exe):  wmake -f makefile.wat interpreter
#   Translator    (ec.exe ecw.exe):  wmake -f makefile.wat translator
#   Translator Library   (ecw.lib):  wmake -f makefile.wat library
#   Translator Library    (ec.lib):  wmake -f makefile.wat library OS=DOS MANAGED_MEM=1
#   Backend	 (backendw.exe):  wmake -f makefile.wat backend 
#		   (backendc.exe)
#		 Make all targets:  wmake -f makefile.wat
#				    wmake -f makefile.wat all
#	  Make all Win32 Binaries:  wmake -f makefile.wat winall
#	  Make all Dos32 Binaries:  wmake -f makefile.wat dosall
#
#   Make C sources so this tree      
#   can be built with just a	 
#   compiler.  Note that translate   
#   creates c files for both DOS 
#   and Windows		   :  wmake -f makefile.wat translate
#				    wmake -f makefile.wat translate-win  
#				    wmake -f makefile.wat translate-dos 
#
#      Install binaries, source and 
#		    include files:
#	     Windows and dos files  wmake -f makefile.wat install
#		Windows files only  wmake -f makefile.wat installwin
#		    dos files only  wmake -f makefile.wat installdos
#
#		   Run unit tests:
#		     Win32 and DOS  wmake -f makefile.wat test
#			Win32 Only  wmake -f makefile.wat testwin
#			  DOS Only  wmake -f makefile.wat testdos
#
# The source targets will create a subdirectory called euphoria-r$(SVN_REV). 
# The default for SVN_REV is 'xxx'.
#
#
#   Options:
#		    MANAGED_MEM:  Set this to 1 to use Euphoria's memory cache.
#				  The default is to use straight HeapAlloc/HeapFree calls. ex:
#				      wmake -h -f makefile.wat interpreter MANAGED_MEM=1
#
#			  DEBUG:  Set this to 1 to build debug versions of the targets.  ex:
#				      wmake -h -f makefile.wat interpreter DEBUG=1
#
!ifndef CONFIG
CONFIG=config.wat
!endif
!include $(CONFIG)

BASEPATH=pcre
!include $(BASEPATH)\objects.wat
!include $(TRUNKDIR)\source\version.mak

FULLBUILDDIR=$(BUILDDIR)

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
	keylist.e &
	fwdref.e &
	shift.e &
	inline.e

EU_INTERPRETER_FILES = &
	compress.e &
	backend.e &
	c_out.e &
	cominit.e &
	intinit.e &
	$(TRUNKDIR)\include\std\get.e &
	int.ex

EU_TRANSLATOR_FILES = &
	compile.e &
	ec.ex &
	c_decl.e &
	c_out.e &
	cominit.e &
	traninit.e &
	compress.e
	
!include $(BUILDDIR)\transobj.wat
!include $(BUILDDIR)\intobj.wat
!include $(BUILDDIR)\backobj.wat
!include $(BUILDDIR)\dosobj.wat
!include $(BUILDDIR)\dostrobj.wat
!include $(BUILDDIR)\dosbkobj.wat

EU_BACKEND_OBJECTS = &
!ifndef INT_CODES
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
DEBUGFLAG = /d2 /dEDEBUG /dHEAP_CHECK
#DEBUGFLAG = /d2 /dEDEBUG /dDEBUG_OPCODE_TRACE
DEBUGLINK = debug all
!endif

!ifndef EX
EX=$(EUBIN)\exwc.exe
!endif

EXE=$(EX)
INCDIR=-i $(TRUNKDIR)\include

PWD=$(%cdrive):$(%cwd)

VARS=DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
all :  .SYMBOLIC
    @echo ------- ALL -----------
	wmake -h -f makefile.wat winall $(VARS)
	wmake -h -f makefile.wat dosall $(VARS)

winall : .SYMBOLIC
    @echo ------- WINALL -----------
	wmake -h -f makefile.wat interpreter $(VARS)
	wmake -h -f makefile.wat translator $(VARS)
	wmake -h -f makefile.wat winlibrary $(VARS)
	wmake -h -f makefile.wat backend $(VARS)

dosall : .SYMBOLIC 
    @echo ------- DOSALL -----------
	wmake -h -f makefile.wat dos  $(VARS) MANAGED_MEM=1
	wmake -h -f makefile.wat library  $(VARS) MANAGED_MEM=1 OS=DOS
	wmake -h -f makefile.wat dostranslator  $(VARS) MANAGED_MEM=1 
	wmake -h -f makefile.wat dosbackend  $(VARS) MANAGED_MEM=1

BUILD_DIRS=$(BUILDDIR)\intobj $(BUILDDIR)\transobj $(BUILDDIR)\DOSlibobj $(BUILDDIR)\WINlibobj $(BUILDDIR)\backobj $(BUILDDIR)\dosbkobj $(BUILDDIR)\dosobj $(BUILDDIR)\dostrobj

distclean : .SYMBOLIC clean
!ifndef RM
	@ECHO Please run configure
	error
!endif
	cd pcre
	wmake -f makefile.wat clean
	cd ..
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\back\*.*	
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RMDIR) %i\back
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\*.*	
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RMDIR) %i
	-@for %i in ($(BUILD_DIRS)) do -$(RM) %i.wat
	-$(RM) $(CONFIG)
	-$(RM) pcre\pcre.h
	-$(RM) pcre\config.h
	-$(RM) version.h
	-$(RM) version.e

clean : .SYMBOLIC
!ifndef DELTREE
	@ECHO Please run configure
	error
!endif
	-$(RM) &
	$(BUILDDIR)\ex.exe $(BUILDDIR)\ec.exe $(BUILDDIR)\exw.exe $(BUILDDIR)\exwc.exe $(BUILDDIR)\ecw.exe $(BUILDDIR)\ec.lib $(BUILDDIR)\ecw.lib $(BUILDDIR)\backendw.exe $(BUILDDIR)\backendc.exe $(BUILDDIR)\backendd.exe $(BUILDDIR)\main-.h $(BUILDDIR)\*.sym
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\back\*.obj
	-@for %i in ($(BUILDDIR)\libobj $(BUILDDIR)\winlibobj $(BUILDDIR)\doslibobj) do -$(RMDIR) %i\back
	-@for %i in ($(BUILD_DIRS) $(BUILDDIR)\libobj) do -$(RM) %i\*.*
	-@for %i in ($(BUILDDIR)\libobj $(BUILDDIR)\winlibobj $(BUILDDIR)\doslibobj) do -$(RMDIR) %i
	cd pcre
	wmake -f makefile.wat clean
	cd ..

$(BUILD_DIRS) : .existsonly
	mkdir $@
	mkdir $@\back

!ifeq OS DOS
OSFLAG=EDOS
LIBTARGET=$(BUILDDIR)\ec.lib
!else
OS=WIN
OSFLAG=EWINDOWS
LIBTARGET=$(BUILDDIR)\ecw.lib
!endif

CC = wcc386
!ifeq OS DOS
FE_FLAGS = /w0 /zq /j /zp4 /fpc /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG) /i..\
BE_FLAGS = /w0 /zq /j /zp4 /fpc /5r /ol /zp4 /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(%EBACKEND) $(MEMFLAG) $(DEBUGFLAG)
!else
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG) /I..\
BE_FLAGS = /ol /zp8 /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(%EBACKEND) $(MEMFLAG) $(DEBUGFLAG)
!endif
	
library : .SYMBOLIC version.e version.h runtime
    @echo ------- LIBRARY -----------
	wmake -h -f makefile.wat $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj $(VARS) MANAGED_MEM=$(MANAGED_MEM)

doslibrary : .SYMBOLIC 
    @echo ------- DOS LIBRARY -----------
	wmake -h -f makefile.wat OS=DOS library  $(VARS)

winlibrary : .SYMBOLIC
    @echo ------- WINDOWS LIBRARY -----------
	wmake -h -f makefile.wat OS=WIN library  $(VARS)

runtime: .SYMBOLIC 
    @echo ------- RUNTIME -----------
	set ERUNTIME=/dERUNTIME

backendflag: .SYMBOLIC
	set EBACKEND=/dBACKEND

$(BUILDDIR)\ecw.lib : $(BUILDDIR)\$(OBJDIR)\back $(EU_LIB_OBJECTS)
	wlib -q $(BUILDDIR)\ecw.lib $(EU_LIB_OBJECTS)

$(BUILDDIR)\ec.lib : $(BUILDDIR)\$(OBJDIR)\back $(EU_LIB_OBJECTS)
	wlib -q $(BUILDDIR)\ec.lib $(EU_LIB_OBJECTS)


!ifdef OBJDIR

objlist : .SYMBOLIC
	wmake -h -f Makefile.wat $(VARS) OS=$(OS) EU_NAME_OBJECT=$(EU_NAME_OBJECT) OBJDIR=$(OBJDIR) $(BUILDDIR)\$(OBJDIR).wat EX=$(EUBIN)\exwc.exe

    
$(BUILDDIR)\$(OBJDIR)\back : .EXISTSONLY $(BUILDDIR)\$(OBJDIR)
    -mkdir $(BUILDDIR)\$(OBJDIR)\back

$(BUILDDIR)\$(OBJDIR).wat : $(BUILDDIR)\$(OBJDIR)\main-.c &
!ifndef INT_CODES
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


exwsource : .SYMBOLIC version.e version.h $(BUILDDIR)\$(OBJDIR)\main-.c
ecwsource : .SYMBOLIC version.e version.h $(BUILDDIR)\$(OBJDIR)\main-.c
backendsource : .SYMBOLIC version.e version.h $(BUILDDIR)\$(OBJDIR)\main-.c
ecsource : .SYMBOLIC version.e version.h $(BUILDDIR)\$(OBJDIR)\main-.c
exsource : .SYMBOLIC version.e version.h $(BUILDDIR)\$(OBJDIR)\main-.c

!endif
# OBJDIR

!ifdef EUPHORIA
translate-win : .SYMBOLIC  
    @echo ------- TRANSLATE WIN -----------
	$wmake -h -f makefile.wat exwsource EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h -f makefile.wat ecwsource EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h -f makefile.wat backendsource EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	
translate-dos : .SYMBOLIC 
    @echo ------- TRANSLATE DOS -----------
	wmake -h -f makefile.wat exsource EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj  $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS 
	wmake -h -f makefile.wat ecsource EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=dostrobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -h -f makefile.wat backendsource EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	
translate : .SYMBOLIC translate-win translate-dos


testwin : .SYMBOLIC
	cd ..\tests
	set EUDIR=$(TRUNKDIR) 
	$(EUBIN)\exwc.exe ..\bin\eutest.ex -i ..\include -cc wat -exe $(FULLBUILDDIR)\exwc.exe -ec $(FULLBUILDDIR)\ecw.exe -lib $(FULLBUILDDIR)\ecw.lib
	cd ..\source

testdos : .SYMBOLIC dos
	cd ..\tests
	set EUDIR=$(TRUNKDIR)
	$(EUBIN)\ex.exe ..\bin\eutest.ex -i ..\include -cc wat -exe $(FULLBUILDDIR)\ex.exe -ec $(FULLBUILDDIR)\ec.exe -lib $(FULLBUILDDIR)\ec.lib
	cd ..\source
	
test : .SYMBOLIC testwin testdos

!endif #EUPHORIA	

$(BUILDDIR)\exwc.exe $(BUILDDIR)\exw.exe: $(BUILDDIR)\$(OBJDIR)\int.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) 
	@%create $(BUILDDIR)\$(OBJDIR)\int.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\int.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\int.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\int.lbc library ws2_32
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\int.lbc file %i
	wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\int.lbc name $(BUILDDIR)\exwc.exe
	wrc -q -ad exw.res $(BUILDDIR)\exwc.exe
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\int.lbc name $(BUILDDIR)\exw.exe
	wrc -q -ad exw.res $(BUILDDIR)\exw.exe

interpreter : .SYMBOLIC version.e version.h
	wmake -h -f makefile.wat $(BUILDDIR)\intobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h -f makefile.wat objlist OBJDIR=intobj $(VARS) EU_NAME_OBJECT=EU_INTERPRETER_OBJECTS
	wmake -h -f makefile.wat $(BUILDDIR)\exw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h -f makefile.wat $(BUILDDIR)\exwc.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

install-generic : .SYMBOLIC
	@echo --------- install-generic $(PREFIX) ------------
	if /I $(PWD)==$(PREFIX)\source exit
	for %i in (*.e) do @copy %i $(PREFIX)\source\
	for %i in (*.ex) do @copy %i $(PREFIX)\source\
	if not exist $(PREFIX)\include\std mkdir $(PREFIX)\include\std
	copy ..\include\* $(PREFIX)\include\
	copy ..\include\std\* $(PREFIX)\include\std
	if not exist $(PREFIX)\include\euphoria mkdir $(PREFIX)\include\euphoria
	copy ..\include\euphoria\* $(PREFIX)\include\euphoria
	
	
	
installwin : .SYMBOLIC install-generic installwinbin
	@echo --------- installwin $(PREFIX) ------------

installwinbin : .SYMBOLIC
	@echo --------- installwinbin $(PREFIX) ------------
	@if exist $(BUILDDIR)\ecw.exe copy $(BUILDDIR)\ecw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\exw.exe copy $(BUILDDIR)\exw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\exwc.exe copy $(BUILDDIR)\exwc.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\backendw.exe copy $(BUILDDIR)\backendw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\backendc.exe copy $(BUILDDIR)\backendc.exe $(PREFIX)\bin\

installdos : .SYMBOLIC install-generic installdosbin
	@echo --------- installdos $(PREFIX) ------------
	
installdosbin : .SYMBOLIC
	@echo --------- installdosbin $(PREFIX) ------------
	@if exist $(BUILDDIR)\ex.exe copy $(BUILDDIR)\ex.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\ec.exe copy $(BUILDDIR)\ec.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\backendd.exe copy $(BUILDDIR)\backendd.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\ec.lib copy $(BUILDDIR)\ec.lib $(PREFIX)\bin\
	
install : .SYMBOLIC installwin installdos
	@echo --------- install $(PREFIX) ------------
	
installbin : .SYMBOLIC installwinbin installdosbin
	@echo --------- installbin $(PREFIX) ------------
	
	
$(BUILDDIR)\ecw.exe : $(BUILDDIR)\$(OBJDIR)\ec.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
	@%create $(BUILDDIR)\$(OBJDIR)\ec.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc library ws2_32
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\ec.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\ec.lbc name $(BUILDDIR)\ecw.exe
	wrc -q -ad exw.res $(BUILDDIR)\ecw.exe


translator : .SYMBOLIC version.e version.h
    @echo ------- TRANSLATOR -----------
	wmake -h -f makefile.wat $(BUILDDIR)\transobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj  $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h -f makefile.wat objlist OBJDIR=transobj EU_NAME_OBJECT=EU_TRANSLATOR_OBJECTS $(VARS)
	wmake -h -f makefile.wat $(BUILDDIR)\ecw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dostranslator : .SYMBOLIC version.e version.h
    @echo ------- DOS TRANSLATOR -----------
	wmake -h -f makefile.wat $(BUILDDIR)\dostrobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=dostrobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -h -f makefile.wat objlist OBJDIR=dostrobj EU_NAME_OBJECT=EU_TRANSDOS_OBJECTS $(VARS) OS=DOS
	wmake -h -f makefile.wat $(BUILDDIR)\ec.exe EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=dostrobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

$(BUILDDIR)\backendw.exe :  $(BUILDDIR)\$(OBJDIR)\backend.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- BACKEND WIN -----------
	@%create $(BUILDDIR)\$(OBJDIR)\exwb.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc library ws2_32
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc file %i
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\exwb.lbc name $(BUILDDIR)\backendw.exe
	wrc -q -ad exw.res $(BUILDDIR)\backendw.exe
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\exwb.lbc name $(BUILDDIR)\backendc.exe
	wrc -q -ad exw.res $(BUILDDIR)\backendc.exe


backend : .SYMBOLIC version.e version.h backendflag
    @echo ------- BACKEND -----------
	wmake -h -f makefile.wat $(BUILDDIR)\backobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h -f makefile.wat objlist OBJDIR=backobj EU_NAME_OBJECT=EU_BACKEND_RUNNER_OBJECTS $(VARS)
	wmake -h -f makefile.wat $(BUILDDIR)\backendw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

dosbackend : .SYMBOLIC version.e version.h backendflag
    @echo ------- BACKEND -----------
	wmake -h -f makefile.wat $(BUILDDIR)\dosbkobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -h -f makefile.wat objlist OBJDIR=dosbkobj EU_NAME_OBJECT=EU_DOSBACKEND_RUNNER_OBJECTS $(VARS) OS=DOS
	wmake -h -f makefile.wat $(BUILDDIR)\backendd.exe EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

dos : .SYMBOLIC version.e version.h
    @echo ------- DOS -----------
	wmake -h -f makefile.wat $(BUILDDIR)\dosobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
	wmake -h -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS $(VARS) OS=DOS
	wmake -h -f makefile.wat $(BUILDDIR)\ex.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS

doseubin : .SYMBOLIC version.e version.h
    @echo ------- DOS EUBIN -----------
	wmake -h -f makefile.wat $(BUILDDIR)\dosobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS"
	wmake -h -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS $(VARS) OS=DOS
	wmake -h -f makefile.wat $(BUILDDIR)\ex.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS"

$(BUILDDIR)\backendd.exe : $(BUILDDIR)\$(OBJDIR)\backend.c $(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- DOS BACKEND -----------
	@%create $(BUILDDIR)\$(OBJDIR)\exb.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc option osname='CauseWay'
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc libpath $(%WATCOM)\lib386
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc libpath $(%WATCOM)\lib386\dos
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc format os2 le ^
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc OPTION STACK=262144
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc OPTION QUIET
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc OPTION ELIMINATE
	@%append $(BUILDDIR)\$(OBJDIR)\exb.lbc OPTION CASEEXACT
	@%append $(BUILDDIR)\$(OBJDIR)\int.lbc library ws2_32
	@for %i in ($(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\exb.lbc file %i
	wlink  $(DEBUGLINK) @$(BUILDDIR)\$(OBJDIR)\exb.lbc name $(BUILDDIR)\backendd.exe
	cd $(BUILDDIR)
	le23p backendd.exe
	cwc  backendd.exe
	cd $(TRUNKDIR)\source

$(BUILDDIR)\ex.exe : $(BUILDDIR)\$(OBJDIR)\int.c $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- DOS INTERPRETER -----------
	@%create $(BUILDDIR)\$(OBJDIR)\ex.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc option osname='CauseWay'
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc libpath $(%WATCOM)\lib386
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc libpath $(%WATCOM)\lib386\dos
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc format os2 le ^
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc OPTION STACK=262144
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc OPTION QUIET
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc OPTION ELIMINATE
	@%append $(BUILDDIR)\$(OBJDIR)\ex.lbc OPTION CASEEXACT
	@for %i in ($(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\ex.lbc file %i
	wlink  $(DEBUGLINK) @$(BUILDDIR)\$(OBJDIR)\ex.lbc name $(BUILDDIR)\ex.exe
	cd $(BUILDDIR)
	le23p ex.exe
	cwc  ex.exe
	cd $(TRUNKDIR)\source

$(BUILDDIR)\ec.exe : $(BUILDDIR)\$(OBJDIR)\ec.c $(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- DOS TRANSLATOR EXE -----------
	@%create $(BUILDDIR)\$(OBJDIR)\ec.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option caseexact
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option osname='CauseWay'
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc libpath $(%WATCOM)\lib386
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc libpath $(%WATCOM)\lib386\dos
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc OPTION stub=$(%WATCOM)\binw\cwstub.exe
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc format os2 le ^
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc OPTION STACK=262144
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc OPTION QUIET
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc OPTION ELIMINATE
	@%append $(BUILDDIR)\$(OBJDIR)\ec.lbc OPTION CASEEXACT
	@for %i in ($(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\ec.lbc file %i
	wlink $(DEBUGLINK) @$(BUILDDIR)\$(OBJDIR)\ec.lbc name $(BUILDDIR)\ec.exe
	cd $(BUILDDIR)
	le23p ec.exe
	cwc ec.exe
	cd $(TRUNKDIR)\source

$(BUILDDIR)\intobj\main-.c: $(BUILDDIR)\intobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\transobj\main-.c: $(BUILDDIR)\transobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES)
$(BUILDDIR)\backobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dosobj\main-.c: $(BUILDDIR)\dosobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dostrobj\main-.c: $(BUILDDIR)\dostrobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dosbkobj\main-.c: $(BUILDDIR)\dosbkobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES)

!ifdef EUPHORIA
# We should have ifdef EUPHORIA so that make doesn't decide
# to update rev.e when there is no $(EX)
rev.e : .recheck .always
	$(EX) -i ..\include revget.ex

!ifdef EU_TARGET
!ifdef OBJDIR
$(BUILDDIR)\$(OBJDIR)\main-.c : $(EU_TARGET)ex $(BUILDDIR)\$(OBJDIR)\back $(EU_TRANSLATOR_FILES)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\back\*.*
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	cd  $(BUILDDIR)\$(OBJDIR)
	$(EXE) $(INCDIR) $(TRUNKDIR)\source\ec.ex -wat -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\$(EU_TARGET)ex
	cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex  $(BUILDDIR)\$(OBJDIR)\back $(EU_TRANSLATOR_FILES)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\back\*.*
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	cd $(BUILDDIR)\$(OBJDIR)
	$(EXE) $(INCDIR) $(TRUNKDIR)\source\ec.ex -wat -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\$(EU_TARGET)ex
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

!ifndef INT_CODES 	
$(BUILDDIR)\$(OBJDIR)\back\be_magic.c :  $(BUILDDIR)\$(OBJDIR)\back\be_execute.obj $(TRUNKDIR)\bin\findjmp.ex
	cd $(BUILDDIR)\$(OBJDIR)\back
	$(EXE) $(INCDIR) $(TRUNKDIR)\bin\findjmp.ex be_magic.c
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

version.e: version.mak
    @echo ------- VERSION.E -----------
	@echo global constant MAJ_VER=$(MAJ_VER) > version.e
	@echo global constant MIN_VER=$(MIN_VER) >> version.e
	@echo global constant PAT_VER=$(PAT_VER) >> version.e
	@echo global constant REL_TYPE="$(REL_TYPE)" >> version.e

version.h: version.mak
    @echo ------- VERSION.H -----------
	@echo $#define MAJ_VER $(MAJ_VER) > version.h
	@echo $#define MIN_VER $(MIN_VER) >> version.h
	@echo $#define PAT_VER $(PAT_VER) >> version.h
	@echo $#define REL_TYPE "$(REL_TYPE)" >> version.h

!ifdef PCRE_OBJECTS	
$(PCRE_OBJECTS) : pcre/*.c pcre/pcre.h.windows pcre/config.h.windows
    @echo ------- REG EXP -----------
	cd pcre
	wmake -h -f makefile.wat 
	cd ..
!endif
