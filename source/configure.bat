@echo off
echo # Configuration for Watcom > config.wat

:Loop
IF "%1"=="" GOTO Continue

IF "%1"=="--with-eu3" (
	echo EU3=1 >> config.wat
	cd > config.wat.tmp
	set /p PWD=<config.wat.tmp
	set PWD
	echo PWD=%PWD% >> config.wat
	GOTO EndLoop
)


:EndLoop
SHIFT
GOTO Loop
:Continue
