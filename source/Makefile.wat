# OpenWatcom makefile for Euphoria (Win32)
#
# You must first run configure.bat, supplying any options you might need:
#
#     Run "configure.bat --help" for a list of options.
#
# Syntax:
#   Interpreter (euiw.exe, eui.exe)  : wmake interpreter
#   Translator            (euc.exe)  : wmake translator
#   Translator Library     (eu.lib)  : wmake library
#   Backend 	 eub.exe, eubw.exe)  : wmake backend
#   Supporting Tools                 : wmake tools
#   Code Page Database               : wmake code-page-db
#   Create Documentation in HTML     : wmake htmldoc
#   Create Documentation in PDF      : wmake pdfdoc
#   Create online Documentation HTML : wmake manual
#                                    
#   Clean and remove entire build directory    
#   and configuration                : wmake clobber
#                                    
#   Clean binaries, libraries, including 
#   files that take a long time, object files,    
#   C files and configuration        : wmake distclean
#                                    
#   Clean binaries, libraries, C files,
#   documentation, and object files  : wmake clean
#
#   Clean documentation only         : wmake docsclean
#
#   Clean intermediate files (object files)  
#   but keep documentation, 
#   configuration, C,      
#   library, and binary files        : wmake nearlyclean
#                                    
#   Make all targets                 : wmake
#                                      wmake all
#                                    
#   Make C sources so this tree        
#   can be built without the         
#   EUPHORIA binaries 	             : wmake translate
#                                  
#   Install binaries only            : wmake installbin
#                                    
#   Install binaries, source and     
#   include files                    : wmake install
#                                    
#   Run unit tests using eui.exe     : wmake test
#   Run unit tests using eu.ex       : wmake testeu
#   
#   The source targets will create a subdirectory called euphoria-r$(SVN_REV). 
#   The default for SVN_REV is 'xxx'.
#
#   Options:
#                   MANAGED_MEM:  Set this to 1 to use Euphoria's memory cache.
#                                 The default is to use straight HeapAlloc/HeapFree calls. 
#                                 ex:
#                                     wmake -h interpreter MANAGED_MEM=1
#
#                         DEBUG:  Set this to 1 to build debug versions of the targets.
#                                 ex:
#                                     wmake -h interpreter DEBUG=1
#
#			C_EXTRA:  Set this to add C flags to the command line.
#				  
#                                 You can limit sequences to 100,000 members:
#				  wmake clean C_EXTRA="/DMAX_SEQ_LEN=100000" all
#
#
#                       I_EXTRA:  Set this to arguments you want to append to the interpreter.
#                                 arguments when running the testeu or test target.  This is passed
#                                 to the instances that compile and translate the code.
#
#                    TEST_EXTRA:  Set this to arguments you want to append to the eutest program's 
#                                 arguments.
#
#              TESTFILE or LIST:  Set either of these to set narrow the list of unit test files for
#                                 either the test target or the testeu target.
#
# ex:
# 	wmake testeu I_EXTRA="-D ETYPE_CHECK" 
#
#       This tests using the interpreter with type checking on and writes the results to a log
#       file.
#
# ex:   wmake library DEBUG=1
#
#       Create a copy of eu.lib with debugging on.
#
# ex:   wmake test LIST="t_switch.e t_math.e"
#
#       Run eutest on only two unit test files.
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

FULLBUILDDIR=$(BUILDDIR)

EU_CORE_FILES = &
	block.e &
	common.e &
	coverage.e &
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
	$(BUILDDIR)\$(OBJDIR)\back\be_alloc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_callc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_coverage.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_debug.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_execute.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_main.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_pcre.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_rterror.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_runtime.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_socket.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_symtab.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_syncolor.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_task.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_w.obj &
	$(PCRE_OBJECTS)

EU_LIB_OBJECTS = &
	$(BUILDDIR)\$(OBJDIR)\back\be_alloc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_callc.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_coverage.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_pcre.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_runtime.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_socket.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_syncolor.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_task.obj &
	$(BUILDDIR)\$(OBJDIR)\back\be_w.obj &
	$(PCRE_OBJECTS)

EU_BACKEND_RUNNER_FILES = &
	.\backend.e &
	.\il.e &
	.\cominit.e &
	.\compress.e &
	.\error.e &
	.\intinit.e &
	.\mode.e &
	.\reswords.e &
	.\pathopen.e &
	.\common.e &
	.\backend.ex

EU_INCLUDES = $(TRUNKDIR)\include\std\*.e $(TRUNKDIR)\include\*.e &
		$(TRUNKDIR)\include\euphoria\*.e &
		$(TRUNKDIR)\include\euphoria\debug\*.e

EU_ALL_FILES = *.e $(EU_INCLUDES) &
		 int.ex ec.ex backend.ex

DOCDIR = $(TRUNKDIR)\docs
EU_DOC_SOURCE = &
	$(EU_INCLUDES) &
	$(DOCDIR)\manual.af &
	$(DOCDIR)\*.txt

!ifeq ALIGN4 1
SETALIGN4 = /dEALIGN4
MANAGED_MEM=1
!endif

!ifneq MANAGED_MEM 1
MEMFLAG = /dESIMPLE_MALLOC
!else
MANAGED_FLAG = -D EU_MANAGED_MEM
# heap check only valid if using managed memory.
!ifeq HEAP_CHECK 1
HEAPCHECKFLAG=/dHEAP_CHECK
!endif

!endif

!ifeq RELEASE 1
RELEASE_FLAG = -D EU_FULL_RELEASE
NOASSERT = /dNDEBUG
!endif

!ifneq ASSERT 1
NOASSERT = /dNDEBUG
!endif

!ifndef PREFIX
!ifdef %EUDIR
PREFIX=$(%EUDIR)
!else
PREFIX=C:\euphoria
!endif
!endif

!ifndef EUBIN
EUBIN=$(PREFIX)\bin
!endif

!ifndef BUILDDIR
BUILDDIR=.
!endif

!ifeq INT_CODES 1
#TODO hack
MEMFLAG = $(MEMFLAG) /dINT_CODES
!endif

!ifndef DEBUG
DEBUG=
!endif

!ifeq DEBUG 1
DEBUGFLAG = /d2 /dEDEBUG 
#DEBUGFLAG = /d2 /dEDEBUG /dDEBUG_OPCODE_TRACE
DEBUGLINK = debug all
TRANSDEBUG= -debug
EUDEBUG=-D DEBUG
LIBRARY_NAME=eudbg


!else
LIBRARY_NAME=eu
NOASSERT = /dNDEBUG
!endif

!ifndef EXTRA_STATS
EXTRA_STATS=
!endif

!ifeq EXTRA_STATS 1
EXTRASTATSFLAG=/dEXTRA_STATS
!endif

!ifndef EXTRA_CHECK
EXTRA_CHECK=
!endif

!ifeq EXTRA_CHECK 1
EXTRACHECKFLAG=/dEXTRA_CHECK
!endif

!ifndef EX
EX=$(EUBIN)\eui.exe
!endif

EXE=$(EX)

# The default is to use the interpreter for everything
# That way one can build everything with only the
# interpreter.
# Change to using the EXEs to keep your CPU cool using
# --use-binary-translator
!ifndef EC
EC=$(EXE) -d E32 $(INCDIR) $(EUDEBUG) $(I_FLAGS) $(TRUNKDIR)\source\ec.ex
!endif

EUTEST=$(EXE) -i $(TRUNKDIR)\include $(TRUNKDIR)\source\eutest.ex
#EUTEST=$(EUBIN)\eutest.exe

INCDIR=-i $(TRUNKDIR)\include

PWD=$(%cdrive):$(%cwd)

!ifndef EUDOC
EUDOC=eudoc.exe
!endif

!ifndef CREOLE
CREOLE=creole.exe
!endif

VARS=DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
all :  .SYMBOLIC core
    @echo ------- ALL/OTHERS -----------
	wmake -h backend $(VARS)
	wmake -h binder $(VARS)
	wmake -h shrouder $(VARS)

core : .SYMBOLIC
    @echo ------- CORE -----------
	wmake -h library DEBUG=1 MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
	wmake -h library DEBUG=  MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
	wmake -h interpreter $(VARS)
	wmake -h translator $(VARS)

code-page-db : $(BUILDDIR)\ecp.dat .SYMBOLIC

$(BUILDDIR)\ecp.dat : $(TRUNKDIR)\bin\buildcpdb.ex $(TRUNKDIR)\source\codepage 
	$(BUILDDIR)\eui -i $(TRUNKDIR)\include $(TRUNKDIR)\bin\buildcpdb.ex -p$(TRUNKDIR)\source\codepage -o$(BUILDDIR)

BUILD_DIRS= &
	$(BUILDDIR)\intobj &
	$(BUILDDIR)\transobj &
	$(BUILDDIR)\WINDOWSlibobj &
	$(BUILDDIR)\WINDOWSlibobj1 &
	$(BUILDDIR)\backobj &
	$(BUILDDIR)\eutestdr

INCLUDE_DIR = &
	$(BUILDDIR)\include

distclean : .SYMBOLIC clean
	-$(RM) $(BUILDDIR)\*.wat
	-$(RM) $(CONFIG)
	-$(RM) Makefile
	

clean : .SYMBOLIC mostlyclean docsclean
	-@for %i in ($(BUILD_DIRS) $(INCLUDE_DIR)) do -$(RMDIR) %i
	-$(RM) $(BUILDDIR)\*.lib
	-$(RM) $(BUILDDIR)\*.exe
	-$(RM) $(BUILDDIR)\ver.cache
	
docsclean : .SYMBOLIC
	-@for %i in ($(BUILDDIR)\html\*.*) do -$(RM) %i
	-$(RM) $(BUILDDIR)\html\js\*.js
	-$(RM) $(BUILDDIR)\html\images\*.*
	-$(RMDIR) $(BUILDDIR)\html\js
	-$(RMDIR) $(BUILDDIR)\html\png
	-$(RMDIR) $(BUILDDIR)\html
	-@for %i in ($(BUILDDIR)\docs\*.*) do -$(RM) %i
	-$(RM) $(BUILDDIR)\docs\js\*.js
	-$(RM) $(BUILDDIR)\docs\images\*.*
	-$(RMDIR) $(BUILDDIR)\docs\js
	-$(RMDIR) $(BUILDDIR)\docs\images
	-$(RMDIR) $(BUILDDIR)\docs
	-$(RM) $(BUILDDIR)\euphoria.txt
	-$(RM) $(BUILDDIR)\euphoria.pdf
	
	
	
nearlyclean mostlyclean : .SYMBOLIC	
	-@for %i in ($(BUILD_DIRS)) do -$(RM) %i\*.obj
	-@for %i in ($(BUILD_DIRS)) do -$(RM) %i\back\*.obj	
	-$(RM) $(BUILDDIR)\pcre\*.obj
	-$(RM) $(TRUNKDIR)\tests\ecp.dat
	-$(RM) $(TRUNKDIR)\tests\*.c	
	-$(RM) $(TRUNKDIR)\tests\*.obj
	-$(RM) $(TRUNKDIR)\tests\*.h
	
clobber : .SYMBOLIC distclean
	-$(RM) $(BUILDDIR)\ecp.dat
	-$(RM) $(BUILDDIR)\*.a
	-$(RMDIR) $(BUILDDIR)

$(BUILD_DIRS) : .EXISTSONLY
	mkdir $@
	mkdir $@\back
	
!ifdef PLAT
!ifeq PLAT WINDOWS
OS=WINDOWS
!else
OS=$(PLAT)
!endif
!else
OS=WINDOWS
!endif


# To tell the translator which compiler it should use.
!ifeq OS WINDOWS
TRANS_CC_FLAG=-wat
!else
TRANS_CC_FLAG=-gcc
!endif

OSFLAG=EWINDOWS
LIBTARGET=$(BUILDDIR)\$(LIBRARY_NAME).lib
CC = wcc386
.ERASE
COMMON_FLAGS = $(DEBUGFLAG) -DARCH=ix86
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s  /I$(TRUNKDIR) $(EREL_TYPE)
BE_FLAGS = /ol /zp4 /d$(OSFLAG) /5r /dEWATCOM  /dEOW $(SETALIGN4) $(NOASSERT) $(HEAPCHECKFLAG) $(%ERUNTIME) $(EXTRACHECKFLAG) $(EXTRASTATSFLAG)  $(MEMFLAG) $(EREL_TYPE)

!ifndef OBJDIR
$(LIBTARGET) : .always .recheck
    @echo ------- LIBRARY -----------
	wmake -h $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj$(DEBUG) $(VARS) MANAGED_MEM=$(MANAGED_MEM)

!ifeq DEBUG 1
$(BUILDDIR)\eu.lib : $(LIBTARGET)
	copy $(BUILDDIR)\eudbg.lib $(BUILDDIR)\eu.lib
!endif

library : $(LIBTARGET) .SYMBOLIC
!endif

!ifdef OBJDIR

$(LIBTARGET) : $(BUILDDIR)\$(OBJDIR)\back $(EU_LIB_OBJECTS)
	wlib -q $(LIBTARGET) $(EU_LIB_OBJECTS)

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


exwsource : .SYMBOLIC $(BUILDDIR)\$(OBJDIR)\main-.c
ecwsource : .SYMBOLIC $(BUILDDIR)\$(OBJDIR)\main-.c
backendsource : .SYMBOLIC $(BUILDDIR)\$(OBJDIR)\main-.c
ecsource : .SYMBOLIC $(BUILDDIR)\$(OBJDIR)\main-.c
exsource : .SYMBOLIC $(BUILDDIR)\$(OBJDIR)\main-.c

!endif
# OBJDIR


!ifeq EUPHORIA 1
translate source : .SYMBOLIC  
    @echo ------- TRANSLATE WINDOWS -----------
	wmake -h exwsource EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h ecwsource EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)
	wmake -h backendsource EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)  $(VARS)


$(TRUNKDIR)\tests\ecp.dat : $(BUILDDIR)\ecp.dat
	-copy $(BUILDDIR)\ecp.dat $(TRUNKDIR)\tests

testeu : .SYMBOLIC  $(TRUNKDIR)\tests\ecp.dat
	cd ..\tests
	set EUCOMPILEDIR=$(TRUNKDIR)
	-$(EUTEST) -i ..\include $(TEST_EXTRA) --nocheck -eui "$(FULLBUILDDIR)\eui.exe $(I_EXTRA) -batch $(TRUNKDIR)\source\eu.ex" -euc "$(FULLBUILDDIR)\eui.exe $(I_EXTRA) -batch $(TRUNKDIR)\source\ec.ex" $(LIST) $(TESTFILE)
	cd ..\source

!endif #EUPHORIA

test : .SYMBOLIC $(TRUNKDIR)\tests\ecp.dat $(BUILDDIR)\eubind.exe $(FULLBUILDDIR)\eu.$(LIBEXT) $(BUILDDIR)\eub.exe
	cd ..\tests
	set EUCOMPILEDIR=$(TRUNKDIR) 
	-$(EUTEST) $(TEST_EXTRA) $(VERBOSE_TESTS) -i ..\include -cc wat -eui $(FULLBUILDDIR)\eui.exe -euc $(FULLBUILDDIR)\euc.exe -lib   $(FULLBUILDDIR)\eu.$(LIBEXT) -bind $(FULLBUILDDIR)\eubind.exe -eub $(BUILDDIR)\eub.exe -log $(LIST) $(TESTFILE)
	$(EUTEST) -process-log > $(BUILDDIR)/test-report.txt
	$(EUTEST) -process-log -html > $(BUILDDIR)/test-report.html	
	
	cd ..\source

coverage : .SYMBOLIC code-page-db
	cd ..\tests
	-copy $(BUILDDIR)\ecp.dat .
	$(EUTEST) $(VERBOSE_TESTS) -i ..\include -eui "$(FULLBUILDDIR)\eui.exe" -coverage-db $(FULLBUILDDIR)\unit-test.edb -coverage $(TRUNKDIR)\include -coverage-pp "$(EXE) -i $(TRUNKDIR)\include $(TRUNKDIR)\bin\eucoverage.ex" -coverage-erase $(LIST)
	-del ecp.dat
	cd ..\source

report: .SYMBOLIC
	$(MAKE) ..\reports\report.html
	
..\reports\report.html: $(EU_ALL_FILES)
	cd ..\tests
	set EUCOMPILEDIR=$(TRUNKDIR) 
	-$(EUTEST) $(VERBOSE_TESTS) -i ..\include -cc wat -exe $(FULLBUILDDIR)\eui.exe -euc $(FULLBUILDDIR)\euc.exe -lib   $(FULLBUILDDIR)\eu.$(LIBEXT) -log $(LIST)
	$(EUTEST) -process-log -html > ..\reports\report.html
	cd ..\source

tester: .SYMBOLIC 
	wmake -h $(BUILDDIR)\eutestdr\eutest.exe BUILD_TOOLS=1 OBJDIR=eutestdr

binder : .SYMBOLIC $(BUILDDIR)\eubind.exe

$(BUILDDIR)\eubind.exe : $(BUILDDIR)\euc.exe $(BUILDDIR)\eu.lib
	$(BUILDDIR)\euc -con $(TRANSDEBUG) -lib $(LIBTARGET) -i $(TRUNKDIR)\include -o $(BUILDDIR)\eubind.exe $(TRUNKDIR)\source\bind.ex

shrouder : .SYMBOLIC $(BUILDDIR)\eushroud.exe

$(BUILDDIR)\eushroud.exe :  $(BUILDDIR)\euc.exe $(BUILDDIR)\eu.lib
	$(BUILDDIR)\euc -con $(TRANSDEBUG) -lib $(LIBTARGET) -i $(TRUNKDIR)\include -o $(BUILDDIR)\eushroud.exe $(TRUNKDIR)\source\shroud.ex

tools: .SYMBOLIC
    @echo ------- TOOLS -----------
	wmake -h $(BUILDDIR)\eutest.exe $(VARS)
	wmake -h $(BUILDDIR)\euloc.exe $(VARS)
	wmake -h $(BUILDDIR)\eucoverage.exe $(VARS)
	wmake -h $(BUILDDIR)\eudis.exe $(VARS)
	wmake -h $(BUILDDIR)\eudist.exe $(VARS)

tools-additional: .SYMBOLIC
    @echo ------- ADDITIONAL TOOLS -----------
	wmake -h $(BUILDDIR)\eudoc.exe $(VARS)
	wmake -h $(BUILDDIR)\creole.exe $(VARS)

tools-all: tools tools-additional

get-creole: $(TRUNKDIR)\source\creole\creole.ex
get-eudoc: $(TRUNKDIR)\source\eudoc\eudoc.ex

$(TRUNKDIR)\source\creole\creole.ex :
	hg clone http://scm.openeuphoria.org/hg/creole $(TRUNKDIR)\source\creole

$(TRUNKDIR)\source\eudoc\eudoc.ex :
	hg clone http://scm.openeuphoria.org/hg/eudoc $(TRUNKDIR)\source\eudoc

$(BUILDDIR)\eutest.exe: $(TRUNKDIR)\source\eutest.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\euloc.exe: $(TRUNKDIR)\bin\euloc.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\eucoverage.exe: $(TRUNKDIR)\bin\eucoverage.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\eudis.exe: $(TRUNKDIR)\source\dis.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\eudist.exe: $(TRUNKDIR)\source\eudist.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\eudoc.exe: $(TRUNKDIR)\source\eudoc\eudoc.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

$(BUILDDIR)\creole.exe: $(TRUNKDIR)\source\creole\creole.ex
	$(EUBIN)\euc -con -o $^@ -i $(TRUNKDIR)\include $<

!ifdef OBJDIR

$(BUILDDIR)\$(OBJDIR)\back\be_machine.obj : $(INCLUDE_DIR)\be_ver.h

!endif

$(INCLUDE_DIR) : .EXISTSONLY
	mkdir $^@
     
$(BUILDDIR)\mkver.exe: mkver.c
	owcc -o $@ $<

update-version-cache : .SYMBOLIC $(INCLUDE_DIR)\be_ver.h

$(INCLUDE_DIR)\be_ver.h $(BUILDDIR)\ver.cache : $(INCLUDE_DIR) $(BUILDDIR)\mkver.exe .always .recheck
	$(BUILDDIR)\mkver.exe $(HG) $(BUILDDIR)\ver.cache $(INCLUDE_DIR)\be_ver.h

!ifdef OBJDIR

$(BUILDDIR)\eui.exe $(BUILDDIR)\euiw.exe: $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(CONFIG) eui.rc version_info.rc eu.manifest
	@%create $(BUILDDIR)\$(OBJDIR)\euiw.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\euiw.lbc file %i
	wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euiw.lbc name $(BUILDDIR)\eui.exe
	wrc -q -ad eui.rc $(BUILDDIR)\eui.exe
	wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euiw.lbc name $(BUILDDIR)\euiw.exe
	wrc -q -ad euiw.rc $(BUILDDIR)\euiw.exe
	
!else

$(BUILDDIR)\eui.exe : .always .recheck
	wmake -h $(BUILDDIR)\intobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=intobj $(VARS) EU_NAME_OBJECT=EU_INTERPRETER_OBJECTS
	wmake -h $(BUILDDIR)\eui.exe EX=$(EUBIN)\eui.exe EU_TARGET=int. OBJDIR=intobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
		

!endif

interpreter : .SYMBOLIC $(BUILDDIR)\eui.exe

install : .SYMBOLIC
	@echo --------- install $(PREFIX) ------------
	if /I $(PWD)==$(PREFIX)\source exit
	if not exist $(PREFIX) mkdir $(PREFIX)
	if not exist $(PREFIX)\source mkdir $(PREFIX)\source
	for %i in (*.e) do @copy %i $(PREFIX)\source\
	for %i in (*.ex) do @copy %i $(PREFIX)\source\
	if not exist $(PREFIX)\include\std mkdir $(PREFIX)\include\std
	copy ..\include\* $(PREFIX)\include\
	copy ..\include\std\* $(PREFIX)\include\std
	if not exist $(PREFIX)\include\std\net mkdir $(PREFIX)\include\std\net
	copy ..\include\std\net\* $(PREFIX)\include\std\net
	if not exist $(PREFIX)\include\std\win32 mkdir $(PREFIX)\include\std\win32
	copy ..\include\std\win32\* $(PREFIX)\include\std\win32
	if not exist $(PREFIX)\include\euphoria mkdir $(PREFIX)\include\euphoria
	copy ..\include\euphoria\* $(PREFIX)\include\euphoria
	@if not exist $(PREFIX)\bin mkdir $(PREFIX)\bin
	copy ..\bin\*.ex $(PREFIX)\bin
	copy ..\bin\*.bat $(PREFIX)\bin
	@if exist $(BUILDDIR)\euc.exe copy $(BUILDDIR)\euc.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\euiw.exe copy $(BUILDDIR)\euiw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eui.exe copy $(BUILDDIR)\eui.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eubw.exe copy $(BUILDDIR)\eubw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eub.exe copy $(BUILDDIR)\eub.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eu.lib copy $(BUILDDIR)\eu.lib $(PREFIX)\bin\	
	@if exist $(BUILDDIR)\eudbg.lib copy $(BUILDDIR)\eudbg.lib $(PREFIX)\bin\	
	@if exist $(BUILDDIR)\ecp.dat copy $(BUILDDIR)\ecp.dat $(PREFIX)\bin\	

installbin : .SYMBOLIC
	@if exist $(BUILDDIR)\euc.exe copy $(BUILDDIR)\euc.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\euiw.exe copy $(BUILDDIR)\euiw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eui.exe copy $(BUILDDIR)\eui.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eubw.exe copy $(BUILDDIR)\eubw.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eub.exe copy $(BUILDDIR)\eub.exe $(PREFIX)\bin\
	@if exist $(BUILDDIR)\eu.lib copy $(BUILDDIR)\eu.lib $(PREFIX)\bin\	
	@if exist $(BUILDDIR)\eudbg.lib copy $(BUILDDIR)\eudbg.lib $(PREFIX)\bin\	

!ifdef OBJDIR

$(BUILDDIR)\euc.exe : $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) eu.manifest
	$(RM) $(BUILDDIR)\$(OBJDIR)\euc.lbc
	@%create $(BUILDDIR)\$(OBJDIR)\euc.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\euc.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\euc.lbc option caseexact
	@for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\euc.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\euc.lbc name $(BUILDDIR)\euc.exe
	wrc -q -ad euc.rc $(BUILDDIR)\euc.exe

!else

$(BUILDDIR)\euc.exe : .always .recheck
    @echo ------- TRANSLATOR -----------
	wmake -h $(BUILDDIR)\transobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj  $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=transobj EU_NAME_OBJECT=EU_TRANSLATOR_OBJECTS $(VARS)
	wmake -h $(BUILDDIR)\euc.exe EX=$(EUBIN)\eui.exe EU_TARGET=ec. OBJDIR=transobj $(VARS)

!endif

translator : .SYMBOLIC $(BUILDDIR)\euc.exe

!ifdef OBJDIR
$(BUILDDIR)\eub.exe $(BUILDDIR)\eubw.exe :  $(BUILDDIR)\$(OBJDIR)\main-.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) eu.manifest
    @echo ------- BACKEND WINDOWS -----------
	@%create $(BUILDDIR)\$(OBJDIR)\eub.lbc
	@%append $(BUILDDIR)\$(OBJDIR)\eub.lbc option quiet
	@%append $(BUILDDIR)\$(OBJDIR)\eub.lbc option caseexact
	@for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\eub.lbc file %i
	wlink $(DEBUGLINK) SYS nt op maxe=2 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\eub.lbc name $(BUILDDIR)\eub.exe
	wrc -q -ad eub.rc $(BUILDDIR)\eub.exe
	wlink $(DEBUGLINK) SYS nt_win op maxe=2 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\eub.lbc name $(BUILDDIR)\eubw.exe
	wrc -q -ad eubw.rc $(BUILDDIR)\eubw.exe

!endif

backend : .SYMBOLIC
    @echo ------- BACKEND -----------
	wmake -h $(BUILDDIR)\backobj\main-.c EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
	wmake -h objlist OBJDIR=backobj EU_NAME_OBJECT=EU_BACKEND_RUNNER_OBJECTS $(VARS)
	wmake -h $(BUILDDIR)\eubw.exe EX=$(EUBIN)\eui.exe EU_TARGET=backend. OBJDIR=backobj $(VARS) DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)

$(BUILDDIR)\intobj\main-.c: $(BUILDDIR)\intobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES) $(CONFIG)
$(BUILDDIR)\transobj\main-.c: $(BUILDDIR)\transobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES) $(CONFIG)
$(BUILDDIR)\backobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES) $(CONFIG)

!ifeq EUPHORIA 1
# We should have ifdef EUPHORIA so that make doesn't decide
# to update rev.e when there is no $(EX)
be_rev.c : .recheck .always
	$(EX) -i ..\include revget.ex

!ifdef EU_TARGET
!ifdef OBJDIR
$(BUILDDIR)\$(OBJDIR)\main-.c : $(EU_TARGET)ex $(EU_TRANSLATOR_FILES) $(BUILDDIR)\$(OBJDIR)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	-$(RM) $(TRUNKDIR)\source\main-.h
	-$(RM) $(TRUNKDIR)\source\init-.c
	-$(RM) $(TRUNKDIR)\source\main-.c
	cd  $(BUILDDIR)\$(OBJDIR)
	$(EC) $(TRANSDEBUG) -nobuild $(TRANS_CC_FLAG) -plat $(OS) -arch X86 $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) -c $(BUILDDIR)\eu.cfg $(TRUNKDIR)\source\$(EU_TARGET)ex $(LIBTARGET)
	cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex  $(BUILDDIR)\$(OBJDIR) $(EU_TRANSLATOR_FILES)
	-$(RM) $(BUILDDIR)\$(OBJDIR)\back\*.*
	-$(RM) $(BUILDDIR)\$(OBJDIR)\*.*
	cd $(BUILDDIR)\$(OBJDIR)
	$(EC)  $(TRANSDEBUG) -nobuild $(TRANS_CC_FLAG) -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) -c $(BUILDDIR)\eu.cfg $(TRUNKDIR)\source\$(EU_TARGET)ex
	cd $(TRUNKDIR)\source
!else
# OBJDIR doesn't exist
$(BUILDDIR)\\main-.c $(BUILDDIR)\\$(EU_TARGET)c : .EXISTSONLY
	@echo Error: attempt to create main-.c without OBJDIR defined.
!endif
!else
#EU_TARGET doesn't exist
$(BUILDDIR)\\main-.c $(BUILDDIR)\\c : .EXISTSONLY
	@echo Error: attempt to create main-.c without EU_TARGET defined.
!endif
!else
#No EUPHORIA installed 
$(BUILDDIR)\$(OBJDIR)\main-.c $(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : .EXISTSONLY
	@echo *****************************************************************
	@echo If you have EUPHORIA installed you'll need to run configure again.
	@echo Make is configured to not try to use the interpreter.
	@echo *****************************************************************

!endif

!ifdef OBJDIR
!ifeq OBJDIR backobj
# this is the .i runner target
BE_FLAGS = $(BE_FLAGS) /DBACKEND
!endif
!ifeq OBJDIR WINDOWSlibobj$(DEBUG)
# this is the library target
BE_FLAGS = $(BE_FLAGS) /dERUNTIME
!endif

.c: $(BUILDDIR)\$(OBJDIR);$(BUILDDIR)\$(OBJDIR)\back
.c.obj: 
	$(CC) $(FE_FLAGS) $(BE_FLAGS) $(COMMON_FLAGS) -fr=$^@.err /I$(BUILDDIR)\$(OBJDIR) /I$(INCLUDE_DIR) $[@ -fo=$^@
	
$(BUILDDIR)\$(OBJDIR)\back\be_inline.obj : .\be_inline.c $(BUILDDIR)\$(OBJDIR)\back
	$(CC) /oe=40 $(BE_FLAGS) $(FE_FLAGS) $(COMMON_FLAGS) $^&.c -fo=$^@

!ifneq INT_CODES 1
$(BUILDDIR)\$(OBJDIR)\back\be_magic.c :  $(BUILDDIR)\$(OBJDIR)\back\be_execute.obj $(TRUNKDIR)\source\findjmp.ex
	cd $(BUILDDIR)\$(OBJDIR)\back
	$(EXE) $(INCDIR) $(TRUNKDIR)\source\findjmp.ex
	cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\back\be_magic.obj : $(BUILDDIR)\$(OBJDIR)\back\be_magic.c
	$(CC) $(FE_FLAGS) $(BE_FLAGS) $(COMMON_FLAGS) $[@ -fo=$^@
!endif

$(BUILDDIR)\$(OBJDIR)\back\be_execute.obj : be_execute.c *.h $(CONFIG)
$(BUILDDIR)\$(OBJDIR)\back\be_decompress.obj : be_decompress.c *.h $(CONFIG) 
$(BUILDDIR)\$(OBJDIR)\back\be_debug.obj : be_debug.c *.h $(CONFIG) 
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

# end of OBJDIR exists
!endif

!ifdef PCRE_OBJECTS	
$(PCRE_OBJECTS) : pcre/*.c pcre/pcre.h.windows pcre/config.h.windows
    @echo ------- REG EXP -----------
	cd pcre
	wmake -h -f makefile.wat CONFIG=..\$(CONFIG) EOSTYPE=-D$(OSFLAG)
	cd ..
!endif

###############################################################################
#
# Documentation
#
###############################################################################

#
# HTML Manual
#

htmldoc: .SYMBOLIC $(BUILDDIR)\html\style.css $(BUILDDIR)\html\images\prev.png $(BUILDDIR)\html\images\next.png $(BUILDDIR)\html\index.html

$(BUILDDIR)\docs\js : .EXISTSONLY $(BUILDDIR)\docs  
	mkdir $^@

$(BUILDDIR)\docs\images : .EXISTSONLY $(BUILDDIR)\docs 
	mkdir $^@

$(BUILDDIR)\docs: .EXISTSONLY
	mkdir $^@
	
$(BUILDDIR)\docs\style.css : $(DOCDIR)\style.css $(BUILDDIR)\docs
	copy $(DOCDIR)\style.css $(BUILDDIR)\docs

$(BUILDDIR)\html\js : .EXISTSONLY $(BUILDDIR)\html  
	mkdir $^@

$(BUILDDIR)\html\images : .EXISTSONLY $(BUILDDIR)\html 
	mkdir $^@

$(BUILDDIR)\html: .EXISTSONLY
	mkdir $^@
	
$(BUILDDIR)\html\style.css : $(DOCDIR)\style.css $(BUILDDIR)\html
	copy $(DOCDIR)\style.css $(BUILDDIR)\html

$(BUILDDIR)\html\images\prev.png : $(DOCDIR)\html\images\prev.png $(BUILDDIR)\html\images
	copy $(DOCDIR)\html\images\prev.png $^@
	
$(BUILDDIR)\html\images\next.png : $(DOCDIR)\html\images\next.png $(BUILDDIR)\html\images
	copy $(DOCDIR)\html\images\next.png $^@

$(BUILDDIR)\docs\images\prev.png : $(DOCDIR)\html\images\prev.png $(BUILDDIR)\docs\images
	copy $(DOCDIR)\html\images\prev.png $^@
	
$(BUILDDIR)\docs\images\next.png : $(DOCDIR)\html\images\next.png $(BUILDDIR)\docs\images
	copy $(DOCDIR)\html\images\next.png $^@

$(BUILDDIR)\euphoria.txt : $(EU_DOC_SOURCE) $(BUILDDIR)\html
	$(EUDOC) -d HTML --strip=2 -a $(TRUNKDIR)\docs\manual.af -o $(BUILDDIR)\euphoria.txt

$(BUILDDIR)\docs\index.html : $(BUILDDIR)\euphoria.txt $(DOCDIR)\template.html $(BUILDDIR)\docs
	cd $(TRUNKDIR)\docs
	$(CREOLE) -A -t=$(TRUNKDIR)\docs\template.html -o=$(BUILDDIR)\docs $(BUILDDIR)\euphoria.txt
	cd $(TRUNKDIR)\source

$(BUILDDIR)\html\index.html : $(BUILDDIR)\euphoria.txt $(DOCDIR)\offline-template.html $(BUILDDIR)\html
	cd $(TRUNKDIR)\docs
	$(CREOLE) -A -t=$(TRUNKDIR)\docs\offline-template.html -o=$(BUILDDIR)\html $(BUILDDIR)\euphoria.txt
	cd $(TRUNKDIR)\source

#
# PDF manual
#

pdfdoc : $(BUILDDIR)\euphoria.pdf

$(BUILDDIR)\pdf : .EXISTSONLY
	mkdir $^@

$(BUILDDIR)\pdf\euphoria.txt : $(EU_DOC_SOURCE) $(BUILDDIR)\pdf
	$(EUDOC) -d PDF --single --strip=2 -a $(TRUNKDIR)\docs\manual.af -o $(BUILDDIR)\pdf\euphoria.txt

$(BUILDDIR)\pdf\euphoria.tex : $(BUILDDIR)\pdf\euphoria.txt $(TRUNKDIR)\docs\template.tex $(BUILDDIR)\pdf
	$(CREOLE) -f latex -A -t=$(TRUNKDIR)\docs\template.tex -o=$(BUILDDIR)\pdf $<

$(BUILDDIR)\euphoria.pdf : $(BUILDDIR)\pdf\euphoria.tex $(BUILDDIR)\pdf
	cd $(TRUNKDIR)\docs
	pdflatex -aux-directory=$(BUILDDIR)\pdf -output-directory=$(BUILDDIR) $(BUILDDIR)\pdf\euphoria.tex
	cd $(TRUNKDIR)\source

pdfdoc-again: .SYMBOLIC $(BUILDDIR)\euphoria.pdf $(BUILDDIR)\pdf
	cd $(TRUNKDIR)\docs
	pdflatex -aux-directory=$(BUILDDIR)\pdf -output-directory=$(BUILDDIR) $(BUILDDIR)\pdf\euphoria.tex
	cd $(TRUNKDIR)\source

#
# Distribution
#

manual : .SYMBOLIC $(BUILDDIR)\docs\index.html $(BUILDDIR)\docs\js\search.js $(BUILDDIR)\docs\style.css  $(BUILDDIR)\docs\images\next.png $(BUILDDIR)\docs\images\prev.png

manual-send: .SYMBOLIC manual
	$(SCP) $(TRUNKDIR)/docs/style.css $(BUILDDIR)/docs/*.html $(OE_USERNAME)@openeuphoria.org:/home/euweb/docs

manual-reindex: .SYMBOLIC
	$(SSH) $(OE_USERNAME)@openeuphoria.org "cd /home/euweb/prod/euweb/source/ && sh reindex_manual.sh"

manual-upload: manual-send manual-reindex
