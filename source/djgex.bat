@echo off
rem     Build Euphoria for DOS32 using DJGPP
rem
rem     you can add: -DEXTRA_CHECK -DEXTRA_STATS 
rem              or: -DHEAP_CHECK
rem     to gopts file to build a debug version
del *.o

echo translating the front end...
mkdir obj
cd obj
@rem ..\..\bin\ec -djg -i ..\..\include ..\int.ex

rem don't compile with emake.bat, use this instead...

echo compiling the front-end files...
SET FEFLAGS=-c -w -fsigned-char -O2 -ffast-math -fomit-frame-pointer -I..\.. 

@rem gcc %FEFLAGS% INIT-.c 2> INIT-.err
@rem gcc %FEFLAGS% MAIN-.c 2> MAIN-.err
@rem gcc %FEFLAGS% MAIN-0.c 2> MAIN-0.err
@rem gcc %FEFLAGS% INT.c 2> INT.err
@rem gcc %FEFLAGS% MODE.c 2> MODE.err
@rem gcc %FEFLAGS% WILDCARD.c 2> WILDCARD.err
@rem gcc %FEFLAGS% TEXT.c 2> TEXT.err
@rem gcc %FEFLAGS% FILESYS.c 2> FILESYS.err
@rem gcc %FEFLAGS% INTERRUP.c 2> INTERRUP.err
@rem gcc %FEFLAGS% MEMORY.c 2> MEMORY.err
@rem gcc %FEFLAGS% 0EMORY.c 2> 0EMORY.err
@rem gcc %FEFLAGS% SORT.c 2> SORT.err
@rem gcc %FEFLAGS% SEARCH.c 2> SEARCH.err
@rem gcc %FEFLAGS% TYPES.c 2> TYPES.err
@rem gcc %FEFLAGS% IO.c 2> IO.err
@rem gcc %FEFLAGS% CONVERT.c 2> CONVERT.err
@rem gcc %FEFLAGS% EDS.c 2> EDS.err
@rem gcc %FEFLAGS% GET.c 2> GET.err
@rem gcc %FEFLAGS% PRETTY.c 2> PRETTY.err
@rem gcc %FEFLAGS% DATETIME.c 2> DATETIME.err
@rem gcc %FEFLAGS% C_OUT.c 2> C_OUT.err
@rem gcc %FEFLAGS% SYMTAB.c 2> SYMTAB.err
@rem gcc %FEFLAGS% SYMTAB_0.c 2> SYMTAB_0.err
@rem gcc %FEFLAGS% SYMTAB_1.c 2> SYMTAB_1.err
@rem gcc %FEFLAGS% ERROR.c 2> ERROR.err
@rem gcc %FEFLAGS% FWDREF.c 2> FWDREF.err
@rem gcc %FEFLAGS% FWDREF_0.c 2> FWDREF_0.err
@rem gcc %FEFLAGS% PARSER.c 2> PARSER.err
@rem gcc %FEFLAGS% PARSER_0.c 2> PARSER_0.err
@rem gcc %FEFLAGS% PARSER_1.c 2> PARSER_1.err
@rem gcc %FEFLAGS% PARSER_2.c 2> PARSER_2.err
@rem gcc %FEFLAGS% PARSER_3.c 2> PARSER_3.err
@rem gcc %FEFLAGS% PARSER_4.c 2> PARSER_4.err
@rem gcc %FEFLAGS% PARSER_5.c 2> PARSER_5.err
@rem gcc %FEFLAGS% EMIT.c 2> EMIT.err
@rem gcc %FEFLAGS% EMIT_0.c 2> EMIT_0.err
@rem gcc %FEFLAGS% EMIT_1.c 2> EMIT_1.err
@rem gcc %FEFLAGS% PATHOPEN.c 2> PATHOPEN.err
@rem gcc %FEFLAGS% SCANNER.c 2> SCANNER.err
@rem gcc %FEFLAGS% SCANNE_0.c 2> SCANNE_0.err
@rem gcc %FEFLAGS% SCANNE_1.c 2> SCANNE_1.err
@rem gcc %FEFLAGS% SCINOT.c 2> SCINOT.err
@rem gcc %FEFLAGS% TRANPLAT.c 2> TRANPLAT.err
@rem gcc %FEFLAGS% INTINIT.c 2> INTINIT.err
@rem gcc %FEFLAGS% COMINIT.c 2> COMINIT.err
@rem gcc %FEFLAGS% COMPRESS.c 2> COMPRESS.err
@rem gcc %FEFLAGS% BACKEND.c 2> BACKEND.err
@rem gcc %FEFLAGS% MAIN.c 2> MAIN.err

cd ..

echo compiling the back-end files...
@rem gcc -c @gopts -fomit-frame-pointer -finline-functions be_inline.c -o obj\be_inline.o 2> obj\be_inline.err
@rem gcc -c @gopts -fomit-frame-pointer be_alloc.c -o obj\be_alloc.o 2> obj\be_alloc.err
@rem gcc -c @gopts -fomit-frame-pointer be_execute.c -o obj\be_execute.o 2> obj\be_execute.err
@rem gcc -c @gopts -fomit-frame-pointer be_machine.c -o obj\be_machine.o 2> obj\be_machine.err
@rem gcc -c @gopts -fomit-frame-pointer be_main.c -o obj\be_main.o 2> obj\be_main.err
@rem gcc -c @gopts -fomit-frame-pointer be_rterror.c -o obj\be_rterror.o 2> obj\be_rterror.err
@rem gcc -c @gopts -fomit-frame-pointer be_runtime.c -o obj\be_runtime.o 2> obj\be_runtime.err
@rem gcc -c @gopts -fomit-frame-pointer be_symtab.c -o obj\be_symtab.o 2> obj\be_symtab.err
@rem gcc -c @gopts -fomit-frame-pointer be_syncolor.c -o obj\be_syncolor.o 2> obj\be_syncolor.err
@rem gcc -c @gopts -fomit-frame-pointer be_w.c -o obj\be_w.o 2> obj\be_w.err
@rem gcc -c @gopts be_callc.c -o obj\be_callc.o 2> obj\be_callc.err
@rem gcc -c @gopts -fomit-frame-pointer be_decompress.c -o obj\be_decompress.o 2> obj\be_decompress.err
@rem gcc -c @gopts -fomit-frame-pointer be_regex.c -o obj\be_regex.o 2> obj\be_regex.err
@rem gcc -c @gopts -fomit-frame-pointer be_task.c -o obj\be_task.o 2> obj\be_task.err
@rem gcc -c @gopts -fomit-frame-pointer regex.c -o .\regex.o 2>obj\regex.err
cd obj
gcc -L..\..\bin -oex.exe @..\djgfiles.lnk 2> ex.err	
set LFN=n
@rem strip ex.exe
set LFN=
dir ex.exe

