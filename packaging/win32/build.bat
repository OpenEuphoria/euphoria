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

echo Performing a SVN checkout...
svn co -q http://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/%1 cleanbranch

GOTO DoBuild

REM --
REM -- We had a previous checkout of the same tag/branch. We now need to do an SVN UP
REM -- to make sure it's the latest of it's tag/branch.
REM --

:SvnUpdate
echo Performing a SVN update...
svn update -q
cd ..


REM --
REM -- Build our installer
REM --

:DoBuild
echo Ensuring binaries are compressed
upx ..\..\bin\creolehtml.exe
upx ..\..\bin\eub.exe
upx ..\..\bin\eubind.exe
upx ..\..\bin\eubw.exe
upx ..\..\bin\euc.exe
upx ..\..\bin\eucoverage.exe
upx ..\..\bin\eudoc.exe
upx ..\..\bin\eui.exe
upx ..\..\bin\euiw.exe
upx ..\..\bin\eutest.exe

echo Building our installer...
ISCC.exe /Q euphoria.iss

GOTO Done

:NoTag
echo Usage: build.bat SVN-DIR (i.e. trunk, tags/4.0.0RC1, ...)

:Done
