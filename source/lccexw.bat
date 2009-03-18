@echo off
rem Build the Euphoria Interpreter for Windows, exw.exe, 
rem using the Lcc C compiler

rem del *.obj 

rem echo translating the front end...
REM set SAVEEUINC=%EUINC%
REM SET EUINC=..\include;%EUINC%
REM need quotes so that spaces will work
REM "%EUDIR%\bin\exwc" ec.ex  -lcc int.ex
rem "%EUDIR\bin\ecxw.exe" -lcc int.ex

SET FE_FLAGS=-e3 -w -O -Zp4 -Iintobj -I.. -DCLK_TCK=CLOCKS_PER_SEC
rem lcc %FE_FLAGS% intobj/main-.c
rem if errorlevel 1 goto end
lcc %FE_FLAGS% -e3 intobj/main-0.c
if errorlevel 1 goto end
lcc %FE_FLAGS% -e4 intobj/pathopen.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/init-.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/int.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/error.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/machine.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/symtab.c
if errorlevel 1 goto end
lcc %FE_FLAGS% intobj/scanner.c
lcc %FE_FLAGS% intobj/scanne_0.c
lcc %FE_FLAGS% intobj/emit.c
lcc %FE_FLAGS% intobj/emit_0.c
lcc %FE_FLAGS% intobj/emit_1.c
lcc %FE_FLAGS% intobj/parser.c
lcc %FE_FLAGS% intobj/parser_0.c
lcc %FE_FLAGS% intobj/parser_1.c
lcc %FE_FLAGS% intobj/backend.c
lcc %FE_FLAGS% intobj/compress.c
lcc %FE_FLAGS% intobj/main.c
lcc %FE_FLAGS% intobj/mode.c
lcc %FE_FLAGS% intobj/c_out.c
lcc %FE_FLAGS% intobj/symtab_0.c
lcc %FE_FLAGS% intobj/file.c

echo translating the backend...
SET BE_FLAGS=-w -O -Zp4 -DEWINDOWS -DELCC -DINT_CODES -DCLK_TCK
lcc %BE_FLAGS% be_main.c
lcc %BE_FLAGS% be_symtab.c
lcc %BE_FLAGS% be_callc.c
lcc %BE_FLAGS% be_alloc.c
lcc %BE_FLAGS% be_machine.c
lcc %BE_FLAGS% be_rterror.c
lcc %BE_FLAGS% be_syncolor.c
lcc %BE_FLAGS% be_w.c
lcc %BE_FLAGS% be_inline.c
lcc %BE_FLAGS% be_runtime.c
lcc %BE_FLAGS% be_execute.c
lcc %BE_FLAGS% be_task.c

lcclnk -s -subsystem windows @lccfiles.lnk -o exw.exe
dir exw.exe
:error
:end

