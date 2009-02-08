# OpenWatcom makefile for Euphoria (Win32/DOS32)
#
# You must first run configure.bat, supplying any options you might need:
#
#     --without-euphoria      Use this option if you are building Euphoria 
#                     with only a C compiler.
# 
#     --prefix <dir>  Use this option to specify the location for euphoria to
#                     be installed.  The default is EUDIR, or c:\euphoria,
#                     if EUDIR is not set.
#
#     --eubin <dir>   Use this option to specify the location of the interpreter
#                     binary to use to translate the front end.  The default
#                     is ..\bin
#
#     --managed-mem   Use this option to turn EUPHORIA's memory cache on in
#                     the targets
#
#     --debug         Use this option to turn on debugging symbols
#
#
#     --full          Use this option to so EUPHORIA doesn't report itself
#                     as a development version.
#
# Syntax:
#   Interpreter(exw.exe, exwc.exe):  wmake -f makefile.wat interpreter
#   Translator    (ec.exe ecw.exe):  wmake -f makefile.wat translator
#   Translator Library   (ecw.lib):  wmake -f makefile.wat library
#   Translator Library   (ecw.lib):  wmake -f makefile.wat library
#   Backend         (backendw.exe):  wmake -f makefile.wat backend 
#                   (backendc.exe)
#                 Make all targets:  wmake -f makefile.wat
#                                    wmake -f makefile.wat all
#          Make all Win32 Binaries:  wmake -f makefile.wat winall
#          Make all Dos32 Binaries:  wmake -f makefile.wat dosall
#
#   Make C sources so this tree      
#   can be built with just a         
#   compiler.  Note that translate   
#   creates c files for both DOS 
#   and Windows                   :  wmake -f makefile.wat translate
#                                    wmake -f makefile.wat translate-win  
#                                    wmake -f makefile.wat translate-dos 
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
#                                      wmake -h -f makefile.wat interpreter MANAGED_MEM=1
#
#                          DEBUG:  Set this to 1 to build debug versions of the targets.  ex:
#                                      wmake -h -f makefile.wat interpreter DEBUG=1
#
!ifndef CONFIG
CONFIG=config.wat
!endif
!include $(CONFIG)

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
        tranplat.e &
        compress.e
        
!include $(BUILDDIR)\transobj.wat
!include $(BUILDDIR)\intobj.wat
!include $(BUILDDIR)\backobj.wat
!include $(BUILDDIR)\dosobj.wat
!include $(BUILDDIR)\dostrobj.wat
!include $(BUILDDIR)\dosbkobj.wat

EU_BACKEND_OBJECTS = &
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
        $(BUILDDIR)\$(OBJDIR)\back\be_regex.obj &
        $(BUILDDIR)\$(OBJDIR)\back\regex.obj 
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
        $(BUILDDIR)\$(OBJDIR)\back\be_regex.obj &
        $(BUILDDIR)\$(OBJDIR)\back\regex.obj

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
DEBUGFLAG = /d2 /dEDEBUG /dINT_CODES
DEBUGLINK = debug all
!endif

!ifndef EX
EX=$(EUBIN)\exwc.exe
!endif



EXE=$(EX)
INCDIR=-i $(TRUNKDIR)\include

VARS=DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
all :  .SYMBOLIC
    @echo ------- ALL -----------
        wmake -h -f makefile.wat winall $(VARS)
        wmake -h -f makefile.wat dosall $(VARS)

winall : .SYMBOLIC
    @echo ------- WINALL -----------
        wmake -h -f makefile.wat interpreter $(VARS)
        wmake -h -f makefile.wat translator $(VARS)
        wmake -h -f makefile.wat library $(VARS)
        wmake -h -f makefile.wat backend $(VARS)

dosall : .SYMBOLIC
    @echo ------- DOSALL -----------
        wmake -h -f makefile.wat dos $(VARS)
        wmake -h -f makefile.wat library OS=DOS $(VARS)
        wmake -h -f makefile.wat dostranslator OS=DOS $(VARS)
        wmake -h -f makefile.wat dosbackend OS=DOS $(VARS)

BUILD_DIRS=$(BUILDDIR)\intobj $(BUILDDIR)\transobj $(BUILDDIR)\DOSlibobj $(BUILDDIR)\WINlibobj $(BUILDDIR)\backobj $(BUILDDIR)\dosbkobj $(BUILDDIR)\dosobj $(BUILDDIR)\dostrobj



distclean : .SYMBOLIC clean
!ifndef RM
        @ECHO Please run configure
        error
!endif
        $(RM) config.wat

clean : .SYMBOLIC
        cd $(BUILDDIR)
!ifndef DELTREE
        @ECHO Please run configure
        error
!endif
        -$(RM) &
                ex.exe ec.exe exw.exe exwc.exe ecw.exe ec.lib ecw.lib backendw.exe backendc.exe backendd.exe main-.h
        -@for %i in (*obj) do @$(DELTREE) %i
        -@for %i in (*obj\back) do @$(RMDIR) %i
        -@for %i in (*obj) do @$(RMDIR) %i
        cd $(TRUNKDIR)\source

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
FE_FLAGS = /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s $(MEMFLAG) $(DEBUGFLAG) /I..\
BE_FLAGS = /ol /d$(OSFLAG) /dEWATCOM  /dEOW $(%ERUNTIME) $(%EBACKEND) $(MEMFLAG) $(DEBUGFLAG)

interpreter : .SYMBOLIC
        wmake -h -f makefile.wat $(BUILDDIR)\intobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=intobj EU_NAME_OBJECT=EU_INTERPRETER_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\exw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\exwc.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)

install : .SYMBOLIC installwin installdos
        
translator : .SYMBOLIC 
        wmake -h -f makefile.wat $(BUILDDIR)\transobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=transobj EU_NAME_OBJECT=EU_TRANSLATOR_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\ecw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)

dostranslator : .SYMBOLIC
        wmake -h -f makefile.wat $(BUILDDIR)\dostrobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=dostrobj EU_NAME_OBJECT=EU_TRANSDOS_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\ec.exe EX=$(EUBIN)\ex.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)

dosbackend : .SYMBOLIC backendflag 
    @echo ------- BACKEND -----------
        wmake -h -f makefile.wat $(BUILDDIR)\dosbkobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=dosbkobj EU_NAME_OBJECT=EU_DOSBACKEND_RUNNER_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\backendd.exe EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)

dos : .SYMBOLIC
        wmake -h -f makefile.wat $(BUILDDIR)\dosobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\ex.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS CONFIG=$(CONFIG)

doseubin : .SYMBOLIC
        wmake -h -f makefile.wat $(BUILDDIR)\dosobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS" CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=dosobj EU_NAME_OBJECT=EU_DOS_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\ex.exe EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS DOSEUBIN="-WAT -PLAT DOS" CONFIG=$(CONFIG)

        
library : .SYMBOLIC runtime 
    @echo ------- LIBRARY -----------
        wmake -h -f makefile.wat $(LIBTARGET) OS=$(OS) OBJDIR=$(OS)libobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)

doslibrary : .SYMBOLIC 
        wmake -h -f makefile.wat OS=DOS library

winlibrary : .SYMBOLIC
        wmake -h -f makefile.wat OS=WIN library 

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
        wmake -h -f Makefile.wat        EU_NAME_OBJECT=$(EU_NAME_OBJECT) OBJDIR=$(OBJDIR) $(BUILDDIR)\$(OBJDIR).wat EX=$(EUBIN)\exwc.exe


    
$(BUILDDIR)\$(OBJDIR)\back : .EXISTSONLY $(BUILDDIR)\$(OBJDIR)
    -mkdir $(BUILDDIR)\$(OBJDIR)\back

$(BUILDDIR)\$(OBJDIR).wat : $(BUILDDIR)\$(OBJDIR)\main-.c
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

!ifdef EUPHORIA
translate-win : .SYMBOLIC  
    @echo ------- TRANSLATE WIN -----------
        wmake -h -f makefile.wat exwsource EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=intobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -h -f makefile.wat ecwsource EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=transobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        wmake -h -f makefile.wat backendsource EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM)
        
translate-dos : .SYMBOLIC 
    @echo ------- TRANSLATE DOS -----------
        wmake -h -f makefile.wat exsource EX=$(EUBIN)\exwc.exe EU_TARGET=int. OBJDIR=dosobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
        wmake -h -f makefile.wat ecsource EX=$(EUBIN)\exwc.exe EU_TARGET=ec. OBJDIR=dostrobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
        wmake -h -f makefile.wat backendsource EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=dosbkobj DEBUG=$(DEBUG) MANAGED_MEM=1 OS=DOS
        
translate : .SYMBOLIC translate-win translate-dos


testwin : .SYMBOLIC
        cd ..\tests
        $(EXE) ..\bin\eutest.ex -i ..\include -cc wat -exe $(BUILDDIR)\exwc.exe -ec $(BUILDDIR)\ecw.exe -lib $(BUILDDIR)\ecw.lib
        cd ..\source

testdos : .SYMBOLIC dos
        cd ..\tests
        $(EXE) ..\bin\eutest.ex -i ..\include -cc wat -exe $(BUILDDIR)\ex.exe -ec $(BUILDDIR)\ec.exe -lib $(BUILDDIR)\ec.lib
        cd ..\source
        
test : .SYMBOLIC testwin testdos

!endif #EUPHORIA        

$(BUILDDIR)\exwc.exe $(BUILDDIR)\exw.exe: $(BUILDDIR)\$(OBJDIR)\int.c $(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
        @%create $(BUILDDIR)\$(OBJDIR)\int.lbc
        @%append $(BUILDDIR)\$(OBJDIR)\int.lbc option quiet
        @%append $(BUILDDIR)\$(OBJDIR)\int.lbc option caseexact
        @for %i in ($(EU_CORE_OBJECTS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\int.lbc file %i
        wlink  $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\int.lbc name $(BUILDDIR)\exwc.exe
        wrc -q -ad exw.res $(BUILDDIR)\exwc.exe
        wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\int.lbc name $(BUILDDIR)\exw.exe
        wrc -q -ad exw.res $(BUILDDIR)\exw.exe

install-generic : .SYMBOLIC
        @for %i in (*.e) do @copy %i $(PREFIX)\source\
        @for %i in (*.ex) do @copy %i $(PREFIX)\source\
        @copy ..\include\* $(PREFIX)\include\
        @if not exist $(PREFIX)\include\std mkdir $(PREFIX)\include\std
        @copy ..\include\std\* $(PREFIX)\include\std
        @if not exist $(PREFIX)\include\euphoria mkdir $(PREFIX)\include\euphoria
        @copy ..\include\euphoria\* $(PREFIX)\include\euphoria
        
installwin : .SYMBOLIC install-generic
        @copy $(BUILDDIR)\ecw.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\exw.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\exwc.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\backendw.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\backendc.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\ecw.lib $(PREFIX)\bin\

installdos : .SYMBOLIC install-generic
        @copy $(BUILDDIR)\ec.exe $(PREFIX)\bin\
        @copy $(BUILDDIR)\backendd.exe $(%PREFIX)\bin\
        @copy $(BUILDDIR)\ec.lib $(PREFIX)\bin\
        
        
$(BUILDDIR)\ecw.exe : $(BUILDDIR)\$(OBJDIR)\ec.c $(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
        @%create $(BUILDDIR)\$(OBJDIR)\ec.lbc
        @%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option quiet
        @%append $(BUILDDIR)\$(OBJDIR)\ec.lbc option caseexact
        @for %i in ($(EU_CORE_OBJECTS) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\ec.lbc file %i
        wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\ec.lbc name $(BUILDDIR)\ecw.exe
        wrc -q -ad exw.res $(BUILDDIR)\ecw.exe


$(BUILDDIR)\backendw.exe :  $(BUILDDIR)\$(OBJDIR)\backend.c $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
    @echo ------- BACKEND WIN -----------
        @%create $(BUILDDIR)\$(OBJDIR)\exwb.lbc
        @%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc option quiet
        @%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc option caseexact
        @for %i in ($(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\exwb.lbc file %i
        wlink $(DEBUGLINK) SYS nt_win op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\exwb.lbc name $(BUILDDIR)\backendw.exe
        wrc -q -ad exw.res $(BUILDDIR)\backendw.exe
        wlink $(DEBUGLINK) SYS nt op maxe=25 op q op symf op el @$(BUILDDIR)\$(OBJDIR)\exwb.lbc name $(BUILDDIR)\backendc.exe
        wrc -q -ad exw.res $(BUILDDIR)\backendc.exe


backend : .SYMBOLIC backendflag 
    @echo ------- BACKEND -----------
        wmake -h -f makefile.wat $(BUILDDIR)\backobj\main-.c EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)
        wmake -h -f makefile.wat objlist OBJDIR=backobj EU_NAME_OBJECT=EU_BACKEND_RUNNER_OBJECTS CONFIG=$(CONFIG)
        wmake -h -f makefile.wat $(BUILDDIR)\backendw.exe EX=$(EUBIN)\exwc.exe EU_TARGET=backend. OBJDIR=backobj DEBUG=$(DEBUG) MANAGED_MEM=$(MANAGED_MEM) CONFIG=$(CONFIG)

$(BUILDDIR)\backendd.exe : $(BUILDDIR)\$(OBJDIR)\backend.c $(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
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
        @for %i in ($(EU_DOSBACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)) do @%append $(BUILDDIR)\$(OBJDIR)\exb.lbc file %i
        wlink  $(DEBUGLINK) @$(BUILDDIR)\$(OBJDIR)\exb.lbc name $(BUILDDIR)\backendd.exe
        le23p $(BUILDDIR)\backendd.exe
        cwc  $(BUILDDIR)\backendd.exe

$(BUILDDIR)\ex.exe : $(BUILDDIR)\$(OBJDIR)\int.c $(EU_DOS_OBJECTS) $(EU_BACKEND_OBJECTS)
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
        le23p $(BUILDDIR)\ex.exe
        cwc  $(BUILDDIR)\ex.exe

$(BUILDDIR)\ec.exe : $(BUILDDIR)\$(OBJDIR)\ec.c $(EU_TRANSDOS_OBJECTS) $(EU_BACKEND_OBJECTS)
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
        le23p $(BUILDDIR)\ec.exe
        cwc $(BUILDDIR)\ec.exe

$(BUILDDIR)\intobj\main-.c: $(BUILDDIR)\intobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\transobj\main-.c: $(BUILDDIR)\transobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES)
$(BUILDDIR)\backobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dosobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dostrobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_INCLUDES)
$(BUILDDIR)\dosbkobj\main-.c: $(BUILDDIR)\backobj\back $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_INCLUDES)

!ifdef EUPHORIA
# We should have ifdef EUPHORIA so that make doesn't decide
# to update rev.e when there is no $(EX)
rev.e : .recheck .always
        $(EX) -i ..\include revget.ex

!ifdef EU_TARGET
!ifdef OBJDIR
$(BUILDDIR)\$(OBJDIR)\main-.c : $(EU_TARGET)ex $(BUILDDIR)\$(OBJDIR)\back
        del $(BUILDDIR)\$(OBJDIR)\*.c
        cd  $(BUILDDIR)\$(OBJDIR)
        $(EXE) $(INCDIR) $(TRUNKDIR)\source\ec.ex -wat -plat $(OS) $(RELEASE_FLAG) $(MANAGED_FLAG) $(DOSEUBIN) $(INCDIR) $(TRUNKDIR)\source\$(EU_TARGET)ex
        cd $(TRUNKDIR)\source

$(BUILDDIR)\$(OBJDIR)\$(EU_TARGET)c : $(EU_TARGET)ex $(BUILDDIR)\$(OBJDIR)\back
        del $(BUILDDIR)\$(OBJDIR)\*.c
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
