@echo off
rem Make the backend for Windows, backendw.exe

del *.obj

echo translating the front end for Windows...
%EUDIR%\bin\exwc.exe ec.ex -wat backend.ex

echo compiling the front-end files...
SET FLAGS=/bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s

echo compiling front-end files...
wcc386 %FLAGS% main-.c
wcc386 %FLAGS% init-.c
wcc386 %FLAGS% file.c
wcc386 %FLAGS% machine.c
wcc386 %FLAGS% 0ackend.c
wcc386 %FLAGS% pathopen.c
wcc386 %FLAGS% backend.c
wcc386 %FLAGS% compress.c

echo compiling the back-end files...
REM /dINT_CODES /dHEAP_CHECK
SET BE_FLAGS=/ol /dEWINDOWS /dEWATCOM /dBACKEND
wcc386 %BE_FLAGS% %FLAGS% be_main.c
wcc386 %BE_FLAGS% %FLAGS% be_symtab.c
wcc386 %BE_FLAGS% %FLAGS% be_callc.c
wcc386 %BE_FLAGS% %FLAGS% be_alloc.c
wcc386 %BE_FLAGS% %FLAGS% be_machine.c
wcc386 %BE_FLAGS% %FLAGS% be_rterror.c
wcc386 %BE_FLAGS% %FLAGS% be_w.c
wcc386 %BE_FLAGS% %FLAGS% be_inline.c
wcc386 %BE_FLAGS% %FLAGS% be_runtime.c
wcc386 %BE_FLAGS% %FLAGS% be_task.c
wcc386 %BE_FLAGS% %FLAGS% be_execute.c

echo linking all the files...
wlink SYS nt_win runtime windows=4.0 op maxe=25 op q op symf op el @exwb.lnk
if not exist backendw.exe goto done
rem del *.obj
wrc -q -ad exw.res backendw.exe
upx -q --best backendw.exe
echo you can now bind with: backendw.exe
:done
pause
