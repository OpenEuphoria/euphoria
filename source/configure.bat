@echo off

set BUILDDIR=.
echo # Configuration for Watcom > config.wat

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

echo Unknown option '%1'
GOTO Help

:EndLoop
SHIFT
GOTO Loop
:Continue
IF "%NOEU%" == "" (
	echo EUPHORIA=1 >> config.wat
)
IF "%DISABLED_MANAGED_MEM%" == "" (
	echo MANAGED_MEM=1 >> config.wat
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
cd ..
if exist source\%BUILDDIR% (
	cd > source\%BUILDDIR%\config.wat.tmp
	set /p PWD=<source\%BUILDDIR%\config.wat.tmp
	del source\%BUILDDIR%\config.wat.tmp
) else (
	cd > %BUILDDIR%\config.wat.tmp
	set /p PWD=<%BUILDDIR%\config.wat.tmp
	del %BUILDDIR%\config.wat.tmp
)
set PWD > NUL
cd source

echo TRUNKDIR=%PWD% >> config.wat
if "%BUILDDIR%" == "." (
	echo BUILDDIR=%PWD%\source >> config.wat
) else (
	echo BUILDDIR=%BUILDDIR% >> config.wat
)
if not exist %BUILDDIR%\transobj.wat copy transobj.dst %BUILDDIR%\transobj.wat
if not exist %BUILDDIR%\intobj.wat copy intobj.dst %BUILDDIR%\intobj.wat
if not exist %BUILDDIR%\backobj.wat copy backobj.dst %BUILDDIR%\backobj.wat
if not exist %BUILDDIR%\dosobj.wat copy dosobj.dst %BUILDDIR%\dosobj.wat
if not exist %BUILDDIR%\dosbkobj.wat copy dosbkobj.dst %BUILDDIR%\dosbkobj.wat
if not exist %BUILDDIR%\dostrobj.wat copy dostrobj.dst %BUILDDIR%\dostrobj.wat

copy /y pcre\pcre.h.windows pcre\pcre.h
copy /y pcre\config.h.windows pcre\config.h

GOTO Completed

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
echo     --debug             turn debugging on
echo.

:Completed
