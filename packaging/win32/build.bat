@echo off

REM --
REM -- Ensure that an ISS file was given on the command line
REM --

IF [%1] == [] GOTO NoISSFile

REM --
REM -- Ensure that we set the branch value
REM --

IF [%2] == [] GOTO NoTag

REM --
REM -- If the tag has already been checked out, then just skip to the
REM -- update process
REM --

CD cleanbranch
IF %ERRORLEVEL% EQU 1 GOTO CheckOut
hg pull
hg update -C -r %2
CD ..
GOTO DoBuild

:Checkout

REM --
REM -- Checkout a clean copy of our repository
REM --

echo Performing a checkout...
hg clone ..\.. cleanbranch

GOTO DoBuild

REM --
REM -- Build our installer
REM --

:DoBuild
copy ..\..\source\build\eu.lib ..\..\bin
IF %ERRORLEVEL% EQU 1 GOTO MissingFile
copy ..\..\source\build\eudbg.lib ..\..\bin
IF %ERRORLEVEL% EQU 1 GOTO MissingFile
copy ..\..\source\build\eu.a ..\..\bin
IF %ERRORLEVEL% EQU 1 GOTO MissingFile
copy ..\..\source\build\eudbg.a ..\..\bin
IF %ERRORLEVEL% EQU 1 GOTO MissingFile

echo Ensuring binaries are compressed

copy ..\..\source\build\*.exe ..\..\bin
upx ..\..\bin\creole.exe
upx ..\..\bin\eub.exe
upx ..\..\bin\eubind.exe
upx ..\..\bin\eushroud.exe
upx ..\..\bin\eubw.exe
upx ..\..\bin\euc.exe
upx ..\..\bin\eudis.exe
upx ..\..\bin\eucoverage.exe
upx ..\..\bin\eudoc.exe
upx ..\..\bin\eui.exe
upx ..\..\bin\euiw.exe
upx ..\..\bin\euloc.exe
upx ..\..\bin\eutest.exe

echo Building our installer...
ISCC.exe /Q %1

GOTO Done

:MissingFile
echo.
echo ** ERROR **
echo Mising file
echo.

GOTO Done

:NoTag
:NoISSFile
echo.
echo ** ERROR **
echo.
echo Usage: build.bat package-name.iss tag
echo.

:Done
