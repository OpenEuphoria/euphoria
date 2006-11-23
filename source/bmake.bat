@echo off
rem Make the backend for DOS, backend.exe

del *.obj

echo translating the front end for DOS...
rem ec -wat backend.ex
ex ec.ex -wat backend.ex

echo compiling the front-end files...
SET FLAGS=/w0 /zq /j /zp4 /fpc /5r /otimra /s

wcc386 %FLAGS% main-.c
wcc386 %FLAGS% init-.c
wcc386 %FLAGS% file.c
wcc386 %FLAGS% machine.c
wcc386 %FLAGS% wildcard.c
wcc386 %FLAGS% 0ackend.c
wcc386 %FLAGS% pathopen.c
wcc386 %FLAGS% backend.c
wcc386 %FLAGS% compress.c

echo compiling the back-end files...
REM /dINT_CODES
SET BE_FLAGS=/ol /dEDOS /dEWATCOM /dBACKEND
wcc386 %BE_FLAGS% %FLAGS% be_main.c
wcc386 %BE_FLAGS% %FLAGS% be_symtab.c
wcc386 %BE_FLAGS% %FLAGS% be_callc.c
wcc386 %BE_FLAGS% %FLAGS% be_alloc.c
wcc386 %BE_FLAGS% %FLAGS% be_machine.c
wcc386 %BE_FLAGS% %FLAGS% be_rterror.c
wcc386 %BE_FLAGS% %FLAGS% be_w.c
wcc386 /oe=40 %BE_FLAGS% %FLAGS% be_inline.c
wcc386 %BE_FLAGS% %FLAGS% be_runtime.c
wcc386 %BE_FLAGS% %FLAGS% be_task.c
wcc386 %BE_FLAGS% %FLAGS% be_execute.c

echo linking all the files...
wlink FILE backend.obj @exb.lnk
le23p backend.exe
cwc backend.exe
if not exist backend.exe goto done
rem del *.obj
dir backend.exe

:done

