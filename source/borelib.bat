rem make the Borland library for Windows
@echo off
del *.obj
del ecwb.lib
rem take out EXTRA_CHECK and EXTRA_STATS
set PD=%1 
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_w.c
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_alloc.c
bcc32 -q     -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_inline.c
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_machine.c
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_runtime.c
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_task.c
bcc32 -q -w- -c -a4 -Ic:\borland\bcc55\include -O2 -5 %PD% -DEWINDOWS -DEBORLAND -DERUNTIME be_callc.c
tlib /0 ecwb.lib /a be_w.obj be_alloc.obj be_inline.obj be_machine.obj be_runtime.obj be_task.obj be_callc.obj
dir ecwb.lib
