@echo off
rem Build the Euphoria Interpreter for Windows, exw.exe, 
rem using the Lcc C compiler

del *.obj 

echo translating the front end...
..\bin\ecw -lcc int.ex

SET FE_FLAGS=-w -O -Zp4 
lcc %FE_FLAGS% main-.c
lcc %FE_FLAGS% main-0.c
lcc %FE_FLAGS% pathopen.c
lcc %FE_FLAGS% init-.c
lcc %FE_FLAGS% int.c
lcc %FE_FLAGS% error.c
lcc %FE_FLAGS% machine.c
lcc %FE_FLAGS% symtab.c
lcc %FE_FLAGS% scanner.c
lcc %FE_FLAGS% scanne_0.c
lcc %FE_FLAGS% emit.c
lcc %FE_FLAGS% emit_0.c
lcc %FE_FLAGS% emit_1.c
lcc %FE_FLAGS% parser.c
lcc %FE_FLAGS% parser_0.c
lcc %FE_FLAGS% parser_1.c
lcc %FE_FLAGS% backend.c
lcc %FE_FLAGS% compress.c
lcc %FE_FLAGS% main.c
lcc %FE_FLAGS% mode.c
lcc %FE_FLAGS% c_out.c
lcc %FE_FLAGS% symtab_0.c

echo translating the backend...
SET BE_FLAGS=-w -O -Zp4 -DEWINDOWS -DELCC -DINT_CODES
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
 
lcclnk -s -subsystem windows @lccfiles.lnk -o exw.exe
dir exw.exe


