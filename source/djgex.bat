@echo off
rem     Build Euphoria for DOS32 using DJGPP
rem
rem     you can add: -DEXTRA_CHECK -DEXTRA_STATS 
rem              or: -DHEAP_CHECK
rem     to gopts file to build a debug version
del *.o

echo translating the front end...
mkdir dosobj
cd dosobj
..\..\bin\ec -djg -i ..\..\include ..\int.ex

rem don't compile with emake.bat, use this instead...

echo compiling the front-end files...
SET FEFLAGS=-c -w -fsigned-char -O2 -ffast-math -fomit-frame-pointer -I..\.. -DEDJGPP 

gcc %FEFLAGS% INIT-.c 2> INIT-.err
gcc %FEFLAGS% MAIN-.c 2> MAIN-.err
gcc %FEFLAGS% MAIN-0.c 2> MAIN-0.err
gcc %FEFLAGS% INT.c 2> INT.err
gcc %FEFLAGS% MODE.c 2> MODE.err
gcc %FEFLAGS% WILDCARD.c 2> WILDCARD.err
gcc %FEFLAGS% TEXT.c 2> TEXT.err
gcc %FEFLAGS% FILESYS.c 2> FILESYS.err
gcc %FEFLAGS% INTERRUP.c 2> INTERRUP.err
gcc %FEFLAGS% MEMORY.c 2> MEMORY.err
gcc %FEFLAGS% 0EMORY.c 2> 0EMORY.err
gcc %FEFLAGS% SORT.c 2> SORT.err
gcc %FEFLAGS% SEARCH.c 2> SEARCH.err
gcc %FEFLAGS% TYPES.c 2> TYPES.err
gcc %FEFLAGS% IO.c 2> IO.err
gcc %FEFLAGS% CONVERT.c 2> CONVERT.err
gcc %FEFLAGS% EDS.c 2> EDS.err
gcc %FEFLAGS% GET.c 2> GET.err
gcc %FEFLAGS% PRETTY.c 2> PRETTY.err
gcc %FEFLAGS% DATETIME.c 2> DATETIME.err
gcc %FEFLAGS% C_OUT.c 2> C_OUT.err
gcc %FEFLAGS% SYMTAB.c 2> SYMTAB.err
gcc %FEFLAGS% SYMTAB_0.c 2> SYMTAB_0.err
gcc %FEFLAGS% SYMTAB_1.c 2> SYMTAB_1.err
gcc %FEFLAGS% ERROR.c 2> ERROR.err
gcc %FEFLAGS% FWDREF.c 2> FWDREF.err
gcc %FEFLAGS% FWDREF_0.c 2> FWDREF_0.err
gcc %FEFLAGS% PARSER.c 2> PARSER.err
gcc %FEFLAGS% PARSER_0.c 2> PARSER_0.err
gcc %FEFLAGS% PARSER_1.c 2> PARSER_1.err
gcc %FEFLAGS% PARSER_2.c 2> PARSER_2.err
gcc %FEFLAGS% PARSER_3.c 2> PARSER_3.err
gcc %FEFLAGS% PARSER_4.c 2> PARSER_4.err
gcc %FEFLAGS% PARSER_5.c 2> PARSER_5.err
gcc %FEFLAGS% EMIT.c 2> EMIT.err
gcc %FEFLAGS% EMIT_0.c 2> EMIT_0.err
gcc %FEFLAGS% EMIT_1.c 2> EMIT_1.err
gcc %FEFLAGS% PATHOPEN.c 2> PATHOPEN.err
gcc %FEFLAGS% SCANNER.c 2> SCANNER.err
gcc %FEFLAGS% SCANNE_0.c 2> SCANNE_0.err
gcc %FEFLAGS% SCANNE_1.c 2> SCANNE_1.err
gcc %FEFLAGS% SCINOT.c 2> SCINOT.err
gcc %FEFLAGS% TRANPLAT.c 2> TRANPLAT.err
gcc %FEFLAGS% INTINIT.c 2> INTINIT.err
gcc %FEFLAGS% COMINIT.c 2> COMINIT.err
gcc %FEFLAGS% COMPRESS.c 2> COMPRESS.err
gcc %FEFLAGS% BACKEND.c 2> BACKEND.err
gcc %FEFLAGS% MAIN.c 2> MAIN.err

cd ..

echo compiling the back-end files...
gcc -c @gopts -fomit-frame-pointer -finline-functions be_inline.c -o dosobj\be_inline.o 2> dosobj\be_inline.err
gcc -c @gopts -fomit-frame-pointer be_alloc.c -o dosobj\be_alloc.o 2> dosobj\be_alloc.err
gcc -c @gopts -fomit-frame-pointer be_execute.c -o dosobj\be_execute.o 2> dosobj\be_execute.err
gcc -c @gopts -fomit-frame-pointer be_machine.c -o dosobj\be_machine.o 2> dosobj\be_machine.err
gcc -c @gopts -fomit-frame-pointer be_main.c -o dosobj\be_main.o 2> dosobj\be_main.err
gcc -c @gopts -fomit-frame-pointer be_rterror.c -o dosobj\be_rterror.o 2> dosobj\be_rterror.err
gcc -c @gopts -fomit-frame-pointer be_runtime.c -o dosobj\be_runtime.o 2> dosobj\be_runtime.err
gcc -c @gopts -fomit-frame-pointer be_symtab.c -o dosobj\be_symtab.o 2> dosobj\be_symtab.err
gcc -c @gopts -fomit-frame-pointer be_syncolor.c -o dosobj\be_syncolor.o 2> dosobj\be_syncolor.err
gcc -c @gopts -fomit-frame-pointer be_w.c -o dosobj\be_w.o 2> dosobj\be_w.err
gcc -c @gopts be_callc.c -o dosobj\be_callc.o 2> dosobj\be_callc.err
gcc -c @gopts -fomit-frame-pointer be_decompress.c -o dosobj\be_decompress.o 2> dosobj\be_decompress.err
gcc -c @gopts -fomit-frame-pointer be_regex.c -o dosobj\be_regex.o 2> dosobj\be_regex.err
gcc -c @gopts -fomit-frame-pointer be_task.c -o dosobj\be_task.o 2> dosobj\be_task.err
gcc -c @gopts -fomit-frame-pointer regex.c -o dosobj\regex.o 2>dosobj\regex.err
cd dosobj
gcc -o..\ex.exe @..\djgfiles.lnk -lalleg 2> ex.err
cd ..
set LFN=n
strip ex.exe
set LFN=
dir ex.exe


