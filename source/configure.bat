@echo off

rem ============================================================
rem	Default the build directory to build, not the current dir
rem	============================================================

SET BUILDDIR=build

rem ============================================================
rem Be sure to start with a blank config.wat
rem by simply writing in a comment
rem ============================================================

echo # Configuration for Watcom > config.wat

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
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--build" (
	set BUILDDIR=%2
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

IF "%1" =="--sse2" (
	echo SSE2=-DSSE2=1 >> config.wat
	echo CPU_FLAG=/6r  >> config.wat
	SET SSE2_ENABLED=1
	GOTO EndLoop
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
IF "%NOEU%" == "" (
	echo EUPHORIA=1 >> config.wat
)
IF "%DISABLED_MANAGED_MEM%" == "" (
	echo MANAGED_MEM=1 >> config.wat
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
echo     --without-euphoria
echo     --prefix value
echo     --no-managed-mem    disable managed memory
echo     --eubin value
echo     --build value       set the build directory
echo     --full
echo.
echo Developer Options:
echo     --debug             turn debugging on
echo     --heapcheck         check memory management system
echo     --extracheck        check for when data corruption
echo     --extrastats        generates statistics
echo.

rem ============================================================
rem Batch file is all done
rem ============================================================

:Completed
