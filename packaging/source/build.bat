@ echo off

REM --
REM -- Ensure that a tag name was given as a command line option
REM --

IF [%1] == [] GOTO NoTag

:SvnCheckout

echo Performing a SVN export...
svn export -q http://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/tags/%1 euphoria-src-%1

GOTO DoBuild

:DoBuild

"C:\Program Files\7-Zip\7z.exe" a -r euphoria-src-%1.zip euphoria-src-%1

GOTO Done

:NoTag
echo No tag given on the command line

:Done

