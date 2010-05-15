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

rem ============================================================
rem Be sure to start with a blank config.wat
rem by simply writing in a comment
rem ============================================================

echo # Configuration for Watcom > config.wat
echo ASSERT=1 >> config.wat

rem ============================================================
rem Detect some parameters
rem ============================================================


rem ============================================================
rem Read command line parameters
rem ============================================================

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
IF "%1" =="--full" (
	echo RELEASE=1 >> config.wat
	GOTO EndLoop
)
IF "%1" =="--debug" (
	echo DEBUG=1 >> config.wat
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

IF "%1" == "--align4" (
	echo ALIGN4=1 >> config.wat
	GOTO EndLoop
)

IF "%1" == "--noassert" (
	echo ASSERT=0 >> config.wat
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

if "%HAS_EUBIN%" == "1" (
SET NOEU=
) else (
wtouch nothing.ex
eui nothing.ex 2> NUL
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
echo.
echo     --prefix value      Use this option to specify the location for euphoria to
echo                         be installed.  The default is EUDIR, or c:\euphoria,
echo                         if EUDIR is not set.
echo.
echo     --no-managed-mem    disable managed memory
echo     --align4            malloc allocates addresses that are
echo                         not always 8 byte aligned.
echo.
echo     --eubin value       Use this option to specify the location of the 
echo                         interpreter binary to use to translate the front end.  
echo                         The default is ..\bin
echo.
echo     --build value       set the build directory
echo.
pause
echo.
echo     --full              Use this option to so EUPHORIA doesn't report itself
echo 		             as a development version.
echo.
echo     --noassert          Use this to remove 'assert()' processing in the C code.
echo.
echo     --plat value        set the OS that we will translate to.
echo                         values can be: WIN, OSX, LINUX, FREEBSD, SUNOS, 
echo                         OPENBSD or NETBSD.
echo.
echo     --use-binary-translator
echo                         Use the already built translator rather than 
echo                         interpreting its source
echo
echo     --use-source-translator
echo                         Interpret the translator's source rather than
echo                         using the already built translator (default)
echo.
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

