@ echo off

REM --
REM -- Ensure that a tag name was given as a command line option
REM --

IF [%1] == [] GOTO NoTag

REM --
REM -- If the tag has already been checked out, then just skip to the
REM -- update process
REM --

CD cleanbranch
IF %ERRORLEVEL% EQU 1 GOTO SvnCheckout

REM --
REM -- Is this the branch we are working on?
REM --

svn info | grep URL | grep %1
IF %ERRORLEVEL% EQU 0 GOTO SvnUpdate

echo Previous checkout was of a different tag/branch
cd ..
echo Removing old checkout...
rmdir /s/q cleanbranch

:SvnCheckout

REM --
REM -- We either did not have a checkout or the checkout was of the wrong branch/tag
REM -- and was automatically removed for us.
REM --

echo Performing a SVN export...
svn export -q http://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/%1 euphoria-src-%1
copy ..\..\bin\edw.bat euphoria-src-%1\bin
copy ..\..\bin\shroudw.bat euphoria-src-%1\bin

GOTO DoBuild

:DoBuild

"C:\Program Files\7-Zip\7z.exe" a -r euphoria-src-%1.zip euphoria-src-%1
