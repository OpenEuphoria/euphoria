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
	echo PREFIX="%2" >> config.wat
	SHIFT
	GOTO EndLoop
)
IF "%1" =="--managed-mem" (
	echo MANAGED_MEM=1 >> config.wat
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
:EndLoop
SHIFT
GOTO Loop
:Continue
if "%NOEU%" == "" (
	echo EUPHORIA=1 >> config.wat
)
cd > config.wat.tmp
set /p PWD=<config.wat.tmp
set PWD > NUL
echo SOURCEDIR=%PWD% >> config.wat
echo BUILDDIR=%BUILDDIR% >> config.wat
if not exist %BUILDDIR%\transobj.wat copy transobj.dst %BUILDDIR%\transobj.wat
if not exist %BUILDDIR%\intobj.wat copy intobj.dst %BUILDDIR%\intobj.wat
if not exist %BUILDDIR%\backobj.wat copy backobj.dst %BUILDDIR%\backobj.wat
if not exist %BUILDDIR%\dosobj.wat copy dosobj.dst %BUILDDIR%\dosobj.wat
if not exist %BUILDDIR%\dosbkobj.wat copy dosbkobj.dst %BUILDDIR%\dosbkobj.wat
if not exist %BUILDDIR%\dostrobj.wat copy dostrobj.dst %BUILDDIR%\dostrobj.wat
