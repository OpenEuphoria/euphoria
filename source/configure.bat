@echo off
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
	echo EUBIN="%2" >> config.wat
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
if not exist transobj.wat copy transobj.dst transobj.wat
if not exist intobj.wat copy intobj.dst intobj.wat
if not exist backobj.wat copy backobj.dst backobj.wat
if not exist dosobj.wat copy dosobj.dst dosobj.wat
if not exist dosbkobj.wat copy dosbkobj.dst dosbkobj.wat
if not exist dostrobj.wat copy dostrobj.dst dostrobj.wat
