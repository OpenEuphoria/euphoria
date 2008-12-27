@echo off
del ec.a
set PD=%1
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_alloc.c
gcc -c @gopts %PD% -DERUNTIME -DINT_CODES be_callc.c
gcc -c @gopts %PD% -DERUNTIME -DINT_CODES be_decompress.c
gcc -c @gopts -fomit-frame-pointer -finline-functions %PD% -DERUNTIME -DINT_CODES be_inline.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_machine.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_regex.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_runtime.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_task.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES be_w.c
gcc -c @gopts -fomit-frame-pointer %PD% -DERUNTIME -DINT_CODES regex.c

ar -rc ec.a be_w.o be_alloc.o be_inline.o be_machine.o be_runtime.o be_task.o be_callc.o be_decompress.o be_regex.o regex.o
dir ec.a

