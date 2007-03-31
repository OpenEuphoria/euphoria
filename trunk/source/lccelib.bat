@echo off
rem make the LCC library for Windows
del *.obj
set PD=%1 
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_w.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_alloc.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_inline.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_machine.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_runtime.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_task.c
lcc -nw -O -Zp4 %PD% -DEWINDOWS -DELCC -DERUNTIME -DINT_CODES be_callc.c
lcclib /out:ecwl.lib be_w.obj be_alloc.obj be_inline.obj be_machine.obj be_runtime.obj be_task.obj be_callc.obj
dir ecwl.lib

