@echo off
rem Make the Euphoria Interpreter .exe for Windows

del *.obj

echo translating the front end for Windows...
rem %EUDIR%\bin\ecw -wat int.ex
%EUDIR%\bin\exwc ec.ex -wat int.ex

echo compiling the front-end files...
rem /ol - no faster, slightly bigger .exe, 
rem plus there's a slight risk of a WATCOM bug
SET FLAGS=/bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s

wcc386 %FLAGS% main-.c
wcc386 %FLAGS% main-0.c
wcc386 %FLAGS% pathopen.c
wcc386 /os %FLAGS% init-.c
wcc386 %FLAGS% int.c
wcc386 %FLAGS% wildcard.c
wcc386 %FLAGS% file.c
wcc386 /os %FLAGS% error.c
wcc386 %FLAGS% machine.c
wcc386 %FLAGS% symtab.c
wcc386 %FLAGS% scanner.c
wcc386 %FLAGS% scanne_0.c
wcc386 %FLAGS% emit.c
wcc386 %FLAGS% emit_0.c
wcc386 %FLAGS% emit_1.c
wcc386 %FLAGS% parser.c
wcc386 %FLAGS% parser_0.c
wcc386 %FLAGS% parser_1.c
wcc386 %FLAGS% backend.c
wcc386 %FLAGS% compress.c
wcc386 %FLAGS% main.c

echo compiling the back-end files...
REM /dINT_CODES /dHEAP_CHECK /dINT_CODES -- next line for User Source only
SET BE_FLAGS=/ol /dEWINDOWS /dEWATCOM /dINT_CODES
rem --PRIVATE /ol is necessary to get good code in do_exec()
SET BE_FLAGS=/ol /dEWINDOWS /dEWATCOM
rem --END PRIVATE
wcc386 %BE_FLAGS% %FLAGS% be_main.c
wcc386 %BE_FLAGS% %FLAGS% be_symtab.c
wcc386 %BE_FLAGS% %FLAGS% be_callc.c
wcc386 %BE_FLAGS% %FLAGS% be_alloc.c
wcc386 %BE_FLAGS% %FLAGS% be_machine.c
wcc386 %BE_FLAGS% %FLAGS% be_rterror.c
wcc386 %BE_FLAGS% %FLAGS% be_syncolor.c
wcc386 %BE_FLAGS% %FLAGS% be_w.c
wcc386 /oe=40 %BE_FLAGS% %FLAGS% be_inline.c
wcc386 %BE_FLAGS% %FLAGS% be_runtime.c
wcc386 %BE_FLAGS% %FLAGS% be_task.c
wcc386 %BE_FLAGS% %FLAGS% be_execute.c

echo linking all the files...
wlink SYS nt_win runtime windows=4.0 op maxe=25 op q op symf op el @exw.lnk
if not exist exw.exe goto done
rem del *.obj
wrc -q -ad exw.res exw.exe
rem upx\upx -q --best exw.exe
echo you can now execute: exw.exe
:done

