@echo off
rem For help run: "configure --help"

rem ============================================================
rem	Default the build directory to build, not the current dir
rem ============================================================

SET BUILDDIR=build

rem ============================================================
rem Set variables we will need to blank
rem ============================================================
SET ECBIN=
SET DISABLED_MANAGED_MEM=
SET SCP_CLIENT=pscp -C
SET SSH_CLIENT=plink -C
SET HG=hg
SET DEBUG=
rem ============================================================
rem Be sure to start with a blank config.wat
rem by simply writing in a comment
rem ============================================================

echo # Configuration for Watcom > config.wat
SET ASSERT=1

rem ============================================================
rem Detect some parameters
rem ============================================================

rem ============================================================
rem Read command line parameters
rem ============================================================

SET DISABLED_MANAGED_MEM=
SET SSE2_ENABLED=

:Loop
IF "%1"=="" GOTO Continue

IF "%1"=="--without-euphoria" (
	set NOEU=1
	GOTO EndLoop
)
IF "%1" =="--prefix" (
	echo PREFIX=%2 >> config.wat
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--no-managed-mem" (
	echo MANAGED_MEM=0 >> config.wat
    SET DISABLED_MANAGED_MEM=1
	GOTO EndLoop
)
IF "%1" =="--eubin" (
	echo EUBIN=%2 >> config.wat
    SET HAS_EUBIN=1
	SET THIS_EUBIN=%2\
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--use-binary-translator" (
    SET ECBIN=1
	GOTO EndLoop
)
IF "%1" =="--use-source-translator" (
    SET ECBIN=0
	GOTO EndLoop
)
IF "%1" =="--build" (
	set BUILDDIR=%2
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--plat" (
    echo PLAT=%2  >> config.wat
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--debug" (
	SET DEBUG=1
	GOTO EndLoop
)

IF "%1" =="--heapcheck" (
	echo HEAP_CHECK=1 >> config.wat
	GOTO EndLoop
)

IF "%1" == "--extrastats" (
	echo EXTRA_STATS=1 >> config.wat
	GOTO EndLoop
)

IF "%1" == "--extracheck" (
	echo EXTRA_CHECK=1 >> config.wat
	GOTO EndLoop
)

IF "%1" =="--sse2" (
	echo SSE2=-DSSE2=1 >> config.wat
	echo CPU_FLAG=/6r -DSSE2=1  >> config.wat
	SET SSE2_ENABLED=1
	GOTO EndLoop
)

IF "%1" == "--align4" (
	echo ALIGN4=1 >> config.wat
	GOTO EndLoop
)

IF "%1" == "--noassert" (
	set ASSERT=0
	GOTO EndLoop
)

IF "%1" == "--release" (
	echo EREL_TYPE = /dEREL_TYPE="%2" >> config.wat
	SHIFT
	GOTO EndLoop
)

IF "%1" =="--final" (
	echo EREL_TYPE = /dEREL_TYPE=1 >> config.wat
	GOTO EndLoop
)

IF "%1" == "--verbose-tests" (
	echo VERBOSE_TESTS = -verbose >> config.wat
	SHIFT
	GOTO EndLoop
)

IF "%1" == "--oe-username" (
	echo OE_USERNAME=%2 >> config.wat
	SHIFT
	GOTO EndLoop
)

IF "%1" == "--scp-client" (
	set SCP_CLIENT=%2
	SHIFT
	GOTO EndLoop
)

IF "%1" == "--ssh-client" (
	set SSH_CLIENT=%2
	SHIFT
	GOTO EndLoop
)

IF "%1" == "--wkhtmltopdf" (
	echo WKHTMLTOPDF=1 >> config.wat
	SHIFT
	GOTO EndLoop
)

IF "%1" == "--hg" (
	SET HG=%2
        SHIFT
        GOTO EndLoop
)

IF "%1" == "--help" (
	GOTO Help
)

echo Unknown option '%1'
GOTO Help

:EndLoop
SHIFT
GOTO Loop

rem ============================================================
rem Store our options to the config.wat file
rem ============================================================

:Continue

echo ASSERT=%ASSERT% >> config.wat
echo SCP=%SCP_CLIENT% >> config.wat
echo SSH=%SSH_CLIENT% >> config.wat
echo HG=%HG% >> config.wat

if "%DEBUG%" == "1" (
	echo DEBUG=1 >> config.wat
)
if "%HAS_EUBIN%" == "1" (
	SET NOEU=
) else (
	eui.exe -? 1> NUL 2> NUL
	if "%ERRORLEVEL%" == "9009" (
		set NOEU=1
	) else (
		set NOEU=
	)
)

echo ARCH=ix86 >> config.wat

IF "%NOEU%" == "" (
	echo EUPHORIA=1 >> config.wat
) else (
	echo EUPHORIA=0 >> config.wat
)
IF "%DISABLED_MANAGED_MEM%" == "" (
	echo MANAGED_MEM=1 >> config.wat
)
IF "%ECBIN%" == "1" (
    	echo EC="$(EUBIN)\euc.exe" >> config.wat
)
IF "%SSE2_ENABLED%" == "" (
	echo CPU_FLAG=/5r >> config.wat
)
IF not exist %WINDIR%\command\deltree.exe (
	echo DELTREE=del /Q /S >> config.wat
	echo RM=del /Q >> config.wat
	echo RMDIR=rmdir /Q/S >> config.wat
)
IF exist %WINDIR%\command\deltree.exe (
	echo DELTREE=deltree /y >> config.wat
	echo RM=deltree /y >> config.wat
	echo RMDIR=deltree /y >> config.wat
)
IF not exist %BUILDDIR% mkdir %BUILDDIR%

rem ============================================================
rem Get the full trunk directory name
rem ============================================================

cd ..
cd > config.tmp
set /p TRUNKDIR=<config.tmp
del config.tmp
cd source

rem ============================================================
rem Get the full build directory name
rem ============================================================

cd %BUILDDIR%
cd > config.tmp
set /p FULL_BUILDDIR=<config.tmp
del config.tmp

rem ============================================================
rem Going back to the source directory
rem ============================================================

cd %TRUNKDIR%\source

rem ============================================================
rem Determining where creolehtml and eudoc are
rem ============================================================
rem if exist %THIS_EUBIN%eudoc.exe (
rem 	echo EUDOC=%THIS_EUBIN%eudoc.exe >> config.wat
rem ) else (
rem 	if exist eudoc\eudoc.ex (
rem 		echo EUDOC=%THIS_EUBIN%eui.exe %TRUNKDIR%\source\eudoc\eudoc.ex >> config.wat
rem 	) else (
rem 		echo EUDOC=eudoc.ex >> config.wat
rem 	)
rem )

echo EUDOC=eudoc.exe >> config.wat

rem if exist %THIS_EUBIN%creolehtml.exe (
rem 	echo CREOLEHTML=%THIS_EUBIN%creolehtml.exe >> config.wat
rem ) else (
rem 	if exist eudoc\creole\creolehtml.ex (
rem 		echo CREOLEHTML=%THIS_EUBIN%eui.exe %TRUNKDIR%\source\eudoc\creole\creolehtml.ex >> config.wat
rem 	) else (
rem 		echo CREOLEHTML=creolehtml.ex >> config.wat
rem 	)
rem )

echo CREOLE=creole.exe >> config.wat

rem ============================================================
rem Writing our final configuration vars
rem ============================================================

echo TRUNKDIR=%TRUNKDIR% >> config.wat
echo BUILDDIR=%FULL_BUILDDIR% >> config.wat

rem ============================================================
rem Copy temporary .wat includes
rem ============================================================

if not exist %FULL_BUILDDIR%\transobj.wat copy transobj.dst %FULL_BUILDDIR%\transobj.wat
if not exist %FULL_BUILDDIR%\intobj.wat copy intobj.dst %FULL_BUILDDIR%\intobj.wat
if not exist %FULL_BUILDDIR%\backobj.wat copy backobj.dst %FULL_BUILDDIR%\backobj.wat

rem ============================================================
rem Make a generic Makefile that simply includes Makefile.wat
rem ============================================================

echo !include Makefile.wat > Makefile

rem ============================================================
rem Add a default eu.cfg to the build dir and source dir
rem ============================================================
echo [All] > %BUILDDIR%\eu.cfg
echo -i %TRUNKDIR%\include >> %BUILDDIR%\eu.cfg
echo -eudir %TRUNKDIR% >> %BUILDDIR%\eu.cfg
echo [translate] >> %BUILDDIR%\eu.cfg
echo -com %TRUNKDIR% >> %BUILDDIR%\eu.cfg
if "%DEBUG%" == "1" (
	echo -lib %FULL_BUILDDIR%\eudbg.lib >> %BUILDDIR%\eu.cfg
) else (
	echo -lib %FULL_BUILDDIR%\eu.lib >> %BUILDDIR%\eu.cfg
)
echo [bind]  >> %FULL_BUILDDIR%\eu.cfg
echo -eub %FULL_BUILDDIR%\eub.exe >> %BUILDDIR%\eu.cfg

copy %BUILDDIR%\eu.cfg %TRUNKDIR%\source\eu.cfg

echo Build directory is %BUILDDIR%

rem ============================================================
rem All Done
rem ============================================================

GOTO Completed

rem ============================================================
rem Display Help
rem ============================================================

:Help
echo Configures and prepares the euphoria source for building
echo.
echo CONFIGURE.BAT [options]
echo.
echo Options:
echo     --without-euphoria  Use this option if you are building Euphoria
echo                         with only a C compiler.
echo     --prefix value      Use this option to specify the location for euphoria to
echo                         be installed.  The default is EUDIR, or c:\euphoria,
echo                         if EUDIR is not set.
echo     --no-managed-mem    disable managed memory
echo     --align4            malloc allocates addresses that are
echo                         always 4 byte aligned.
echo     --eubin value       Use this option to specify the location of the
echo                         interpreter binary to use to translate the front end.
echo                         The default is ..\bin
echo     --build value       set the build directory
echo     --release value     set the release type for the version string
echo     --final             Use this option to so EUPHORIA doesn't report itself
echo                         as a development version.
echo     --noassert          Use this to remove 'assert()' processing in the C code.
echo     --plat value        set the OS that we will translate to.
echo                         values can be: WIN, OSX, LINUX, FREEBSD, OPENBSD or NETBSD.
echo     --use-binary-translator
echo                         Use the already built translator rather than
echo                         interpreting its source
echo     --use-source-translator
echo                         Interpret the translator's source rather than
echo                         using the already built translator (default)
echo     --verbose-tests     Cause eutest to use the -verbose flag during testing
echo     --oe-username       Developer user name on openeuphoria.org for various scp
echo                         operations such as manual upload
echo     --scp-client        SCP program to use for scp uploads (default pscp)
echo     --ssh-client        SSH program to use for ssh commands (default plink)
echo     --hg                Full path to hg.exe (default hg)
echo.
echo Developer Options:
echo.
echo Developer Options:
echo     --debug             turn debugging on
echo     --heapcheck         check memory management system
echo     --extracheck        check for data corruption
echo     --extrastats        generates statistics
echo.

rem ============================================================
rem Batch file is all done
rem ============================================================

:Completed

rem ============================================================
rem Set a variable we used to blank
rem ============================================================
SET DISABLED_MANAGED_MEM=

