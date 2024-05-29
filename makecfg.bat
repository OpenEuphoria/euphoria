@ECHO OFF
SET BASEDIR=%~dp0
SET EUDIR=%BASEDIR:~0,-1%
SET CONFIG=%EUDIR%\bin\eu.cfg

:defarch
IF "%PROCESSOR_ARCHITECTURE%" == "x86" SET DEFARCH=X86
IF "%PROCESSOR_ARCHITECTURE%" == "AMD64" SET DEFARCH=X86_64

:setarch32
IF "%1" == "X86" (
  SET ARCH=%1
  GOTO makecfg
)

:setarch64
IF "%1" == "X86_64" (
  SET ARCH=%1
  GOTO makecfg
)

:default
IF "%1" == "" (
  SET ARCH=%DEFARCH%
  GOTO makecfg
)

:badarch
ECHO Invalid arch "%1"
EXIT /B 1

:makedir
IF NOT EXIST %EUDIR%\bin (
  MKDIR %EUDIR%\bin
)

:makecfg
ECHO Writing contents to: %CONFIG%
ECHO [all] > %CONFIG%
ECHO -eudir %EUDIR% >> %CONFIG%
ECHO -i %EUDIR%\include >> %CONFIG%
ECHO [translate] >> %CONFIG%
ECHO -arch %ARCH% >> %CONFIG%
ECHO -gcc >> %CONFIG%
ECHO -com %EUDIR% >> %CONFIG%
ECHO -con >> %CONFIG%
ECHO -lib-pic %EUDIR%\bin\euso.a >> %CONFIG%
ECHO -lib %EUDIR%\bin\eu.a >> %CONFIG%
ECHO [bind] >> %CONFIG%
ECHO -eub %EUDIR%\bin\eub.exe >> %CONFIG%
TYPE %CONFIG%
:done
PAUSE
