@echo off
REM Since Watcom ex.exe crashes when run under DJGPP, use exwc to bootstrap
REM Tested with Watcom exwc (MinGW exwc should also work)
mkdir intobj
cd intobj
del *.c
del *.obj
del *.o
mkdir back
cd back
del *.o
del *.obj
cd ..
exwc -i ..\..\include ..\ec.ex -DJG -D EU_MANAGED_MEM -DJG -PLAT DOS -i ..\..\include ..\int.ex
cd ..
