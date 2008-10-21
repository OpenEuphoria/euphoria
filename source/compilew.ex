-- Compilew.ex      execute better using compilew.bat
-- 
-- Compiles Euphoria 4.0 for WIN32 and DOS32 (Tested only from exwc)
-- 
-- The lazy man compilation tool based on: 
-- http://openeuphoria.org/wiki/euwiki.cgi?Compiling40
--
-- Use at your own risk, if you don't know what are you doing, ask for help.
-- Required installed OpenWatcom
--
-- Required enhacements:
-- 1- Multiplatform (Add Unix specific instructions)
-- 2- Multicompiler (Support more compilers)
-- 3- Check if the dir pointed by environment variables contain that is
--    expected.
-- 4- Adjust environment on the fly (configure its own .bat file)
-- 
-- Marco Achury
-- 

include get.e

procedure ShowHelp()
    object Test
    
    puts (1,"COMPILEW  Compiles Euphoria 4.0 for WIN32 and DOS32\n")
    puts (1,"Required Environmental variables:\n")
    puts (1,"EUDIR pointing to the base for current Euphoria installation\n")
    puts (1,"Current EUDIR=")
    
    Test = getenv("EUDIR")
    if sequence(Test) then
	puts(1, Test)
    end if
    
    puts (1,"\nEUINC pointing to the include dir inside your source directory\n")
    puts (1,"Current EUINC=")
    
    Test = getenv("EUINC")
    if sequence(Test) then
	puts(1, Test)
    end if
    
    puts (1,"\nRequired OpenWatcom\n")
    puts (1,"Current WATCOM=")
    
    Test = getenv("WATCOM")
    if sequence(Test) then
	puts(1, Test)
    end if

    puts (1,"\n\nIf you are not sure please abort and check again\n\n")
    puts (1,"Are you ready to compile? (y/n)")
    
    Test = wait_key()
    if Test != 'y' and Test !='Y' then
	puts(1,"\n\nGood bye!\n\n")
	abort(1)
    else
	puts(1,"\nGreat!...\n")
    end if
    
end procedure
    
-- Checking possible errors before attemp compile.
-- Missing OpenWatcom
procedure PreTest()
    object Test

    Test = command_line()    -- If command line options,
    if length(Test)!= 2 then -- read again the instructions...
	abort (1)
    else
    end if

    Test = getenv("WATCOM")
    if atom(Test) then
	puts (1, "Please reinstall OpenWatcom\n\n")
	abort (1)
    end if
    
    Test = getenv("EUDIR")
    if atom(Test) then
	puts (1, "Needed install Euphoria and set EUDIR\n\n")
	abort (1)
    end if
    
    Test = getenv("EUINC")
    if atom(Test) then
	puts (1, "Needed Euphoria Source and set EUINC\n" &
	"pointing to \\include inside you source dir.\n\n")
	ShowHelp()
	abort (1)
    end if
    
    Test = getenv("EUVISTA")
    if atom(Test) then
	puts (1, "EUVISTA environmental variable is not set,\n" &
	"this may cause problems problems on Windows Vista.\n" &
	"Do you want to continue? (y/n)" )
	Test = wait_key()
	if Test != 'y' and Test !='Y' then
	    puts(1,"\nPlease: set euvista=1\n\n")
	    abort(1)
	end if
	    
    end if
    
end procedure


procedure Main()

    ShowHelp()
    PreTest()
--  C:\> SET EUINC=C:\EU40\include 
--  C:\> cd \EU40\source 
    
    system ("wmake -f makefile.wat clean",2)
    system ("wmake -f makefile.wat distclean",2)
    system ("configure --with-eu3",2)
    system ("wmake -f makefile.wat",2)
--  .... alot of build messages .... 
--  C:\EU40\source> copy *.exe ..\bin 
--  .... a few .exe files go by .... 
--  C:\EU40\source> copy *.lib ..\bin 
--  .... ecw.lib goes by .... 
    system ("dir *.exe",2)
    system ("dir *.lib",2)
    abort(0)
end procedure


Main()

