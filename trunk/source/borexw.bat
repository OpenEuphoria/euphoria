@echo off
rem Batch file for building exw.exe using Borland C
rem for debugging add: -DEXTRA_CHECK and -DEXTRA_STATS, or -DHEAP_CHECK

echo      if be_callc.c generates an Internal compiler error, 
echo      change "be_callc.c" to "be_callc.obj" in borfiles.lnk

del *.obj

echo translating the front end...
..\bin\ecw -bor int.ex

bcc32 -DINT_CODES -DEWINDOWS -DEBORLAND -eexw.exe -tW -q -w- -O2 -5 -a4 -Ic:\borland\bcc55\include -LC:\BORLAND\BCC55\LIB @borfiles.lnk 
del *.tds > NUL

dir exw.exe

