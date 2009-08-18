		Euphoria 3.1 Open Source Software
		---------------------------------

                
How to Build Everything
-----------------------

* On DOS/Windows, simply run build.bat
		
This will build:
   - the normal (C-backend) Interpreter
   - a translated/compiled version of the Translator
   - Translator libraries for the 5 supported C compilers on DOS/Windows

The build script used to shroud the binder, but this is no 
longer necessary and the binder can be run as an open source 
interpreted Euphoria program. See bind.bat, shroud.bat, etc.

Running clean.bat will clean up the source directory by
deleting unnecessary files, such as .obj files.

* On Linux, run:
     ./buildu
		
* On FreeBSD, run:
     ./bsdbuild
  but first check that in global.e, EBSD=TRUE and in backend.ex, EBSD=1


WARNING: Tricky Bits
--------------------
There are places where small bits of machine code are inserted
without the full knowledge of the C compiler. One place is where
a Euphoria program calls a C routine and must push data onto the 
C call stack. The machine language PUSH instruction is inserted.
Another place is where the Translator library must switch C call-stacks
when a transition is made from running one task to running another.
The hardware stack pointer is made to point at a new place.

After building, if you find that things basically work, except
for calls to C, and/or multitasking of translated programs, you'll
need to roll up your sleeves and make some adjustments to hardware
stack offsets. How to do this is described in the C back-end source files 
be_callc.c and be_task.c

Warnings / Error Messages During Build
--------------------------------------

* When building with WATCOM for Windows you will see 
  "Warning(1008): cannot open graph.lib". This can be ignored.

* The DEL command gives a warning when a file to be deleted does not
  exist. Ignore it.
  

How to build the Euphoria interpreter using various C compilers
---------------------------------------------------------------

General Notes:

  Errors/Warnings:
  
  The .def files were generated automatically by the WATCOM compiler
  for Windows (-v option). They contain C function prototypes. They may
  cause a few errors when you compile with Lcc or GNU. Commenting out the
  offending lines in main.def and runtime.def and others will solve the
  problem. If you compile with WATCOM for DOS, at first you'll get
  numerous errors, but on the next try it should work because WATCOM for
  DOS will create it's own .def files. The .def files aren't used at all
  with DJGPP, so there shouldn't be any problem there.
  
  
  Calls To C (Windows, Linux, FreeBSD):
  
  In order to call C routines from the interpreter, we need the ability
  to push arbitrary amounts of data on the machine-level call stack.
  To do this, we must execute a machine-level PUSH instruction, something
  that can't be done directly in C. Inserting the PUSH instruction is 
  simple enough, but we need to say what the operand of the PUSH is. The
  PUSH instruction that we use references a certain offset on the
  stack. That offset must be the offset of our C "arg" variable. The
  trouble is, the C compiler doesn't know what we are doing, so it may
  change the offset of "arg" whenever we add new code, or compile with
  different options etc. We also need to figure out the offset of the
  "argsize" variable.
  
  If the offsets are wrong, Euphoria will crash when you call a C routine, 
  but everything else should run ok. To find the correct offset for "arg", 
  you need to generate an assembly listing for be_callc.c and examine the 
  code for call_c(). With WATCOM (DOS or Windows) you can run:
        
        wdisasm be_callc.obj > be_callc.asm
  
  (In later versions of WATCOM, "wdisasm" might be called "wdis")
        
  With WATCOM, there's no C source mixed in with the assembly listing, 
  unless you compile with -d1, but you don't want to do that for fast
  execution and small .exe size. However if you search for PUSH 
  instructions, you'll find a few places where the argument to be pushed 
  looks like (for example) +46H[EBP]. You'll see that just before these PUSH 
  instructions, there are MOV instructions that reference the correct 
  offset for "arg". If the offset in the PUSH is different, you'll have 
  to edit the push() macro in be_callc.c to make them the same. 
  
  To get an assembly listing with GNU or Lcc you can add the
  -S option to the compile command for be_callc.c
  
  To help you find the offset of "arg" (and "argsize"), there's a dummy
  statement in C:
           
           arg = arg + argsize + 9999;  // 9999 = 270f hex
  
  which you can locate in the assembly listing by looking for "9999"
  or "270f". This will help you find the correct offsets for arg and argsize,
  which you must plug into the push() and pop() macros.
  
  Speed:
  
  The main interpreter switch in be_execute.c can be performed using standard
  case statements, with integer case values for the op codes. This is
  the standard, portable way to do it in C. It can also be done using
  direct jumps from one case to the next. This is called "threaded" code.
  This has nothing to do with parallelism or multithreading. The term 
  "threaded code" originated with the Forth language.
  It saves the overhead of going back through the C switch statement after
  each case is executed.
  
  The GNU-based C compilers, DJGPP (DOS) and GCC (Linux, FreeBSD), have a 
  special non-ANSI extension to C, called "dynamic labels", that makes 
  threaded code easy to achieve. DJGEX.BAT, GNUEXU, and GNUBSD are set 
  up to use this feature, and you should get full-speed "right out of the box".
  
  For the WATCOM compilers (DOS and Windows), RDS has implemented threaded
  code using a low-level hack, that is tricky to maintain, and may
  require adjustment. The IMAKE.BAT and IMAKEW.BAT files therefore 
  are initially set up to use the -DINT_CODES flag, to ensure that you
  get a working interpreter, although one that runs at about half speed.
  
  To get the WATCOM-based interpreters up to full speed, you need to
  remove the -DINT_CODES flag from the batch files, and you need to
  set the correct value for:  int **jumptab in be_execute.c. This value 
  may need adjustment for different versions of WATCOM, different
  debug flags etc. In be_execute.c you'll see:
  
       int **jumptab = ((int **)Execute)+18;
  
  The value 18 is the address of the internal C switch table minus
  the address of Execute(), divided by 4. To find the address of
  the switch table and Execute(), you'll have to run the command:
  
       wdisasm execute.obj > execute.asm
       
  Then look inside the file: execute.asm
  The switch table should be obvious. It comes just after Execute() and
  has over 100 labels in a long list. The WATCOM disassembler shows the 
  relative offsets of the code and data.
  
  For the other compilers, Lcc, you can probably set up the same
  mechanism as RDS has used for WATCOM. You need to know the address of
  the C switch table, and you need a method of jumping dynamically from
  one case to the next. Until you figure that out, you can use
  -DINT_CODES.

  The interactive trace code has been added in this release, but it has never
  been ported/tested completely for  Lcc or DJGPP.


Specific Notes for each C compiler
			
			Euphoria for Windows, exw.exe


WATCOM
======
  build exw.exe with: imakew.bat
  
  Ignore the warning about graph.lib.
  
  The interactive trace, trace(1) should fully work.
  

			Euphoria for DOS, ex.exe

WATCOM
======
  build ex.exe with: imake.bat
  
  In OpenWatcom's Readme file, it is written that OpenWatcom doesn't need the 
  LIB environment variable, that's why it is not set. That's true when 
  linking for Windows, but the LIB variable is necessary to link
  files for DOS.
  
  The interactive trace, trace(1) should fully work.


DJGPP
=====
  build ex.exe with: djgex.bat
  
  It will run at full speed. -DINT_CODES is not used.
  You'll need the Allegro graphics library liballeg.zip from 
  our download page. It's the same file that's used with the Translator.
  
  The interactive trace code will crash. The trace source in
  be_rterror.c was never ported to DJGPP. i.e. trace(1) 
  Some work will be required.

			
			Euphoria for Linux, exu
GNU C
=====
  You'll have to convert the line terminators in the
  source files to the Linux standard of \n, rather than 
  the Windows/DOS form of \r\n, otherwise several files
  will give you errors. You can use: 
       
       exu fixline.ex 
  
  for this. Also, when you save a file using ed.ex, it will let you
  convert to \n terminators. You should also ensure that all 
  source file names are lower case (unzip -L).
  
  build exu with: imakeu
  Make sure it has \n line-terminators, and execute permission
  (chmod +x imakeu).
  
  exu will run at full speed. -DINT_CODES is not used.

  The interactive trace, trace(1) should fully work.
			
			
			Euphoria for FreeBSD, exu
GNU C
=====
  You'll have to convert the line terminators in the
  source files to the Linux standard of \n, rather than 
  the Windows/DOS form of \r\n, otherwise several files
  will give you errors. You can use: 
       
       exu fixline.ex 
  
  for this. Also, when you save a file using ed.ex, it will let you
  convert to \n terminators. You should also ensure that all 
  source file names are lower case (unzip -L).
  
  In global.e, set the constant EBSD to TRUE rather than FALSE.

  In backend.ex set EBSD = 1
  
  build exu with: bsdimakeu
  Make sure it has \n line-terminators, and execute permission
  (chmod +x bsdimakeu).
  
  exu will run at full speed. -DINT_CODES is not used.

  The interactive trace, trace(1) should fully work.

		
		Meanings of the various compile options for (-D):
Platforms:
   EDOS
   EUNIX
   EWINDOWS
   EBSD  (EUNIX must also be defined)
   EOSX
   
Compilers:
   EWATCOM

Translator:
   TRANSLATE (in Euphoria front end)

Binder:
   BIND (in Euphoria front end)
   
Run-time Library:
   ERUNTIME
   
Debug options:
   EXTRA_CHECK EXTRA_STATS   (must do both options together)

To get a portable (slow) interpreter main loop:
   INT_CODES


			Compatibility Notes
DOS

Keep in mind that existing hand-coded machine code routines 
called from Euphoria won't port to DJGPP because low memory addresses
must be accessed in a different way. Euphoria's peek(), poke(), poke4() etc. 
take this into account, but hand-coded user routines probably don't. 
This affects the Translator for DJGPP as well.



