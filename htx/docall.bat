@echo creating DOCUMENTATION FILES

rem need syncolor.e and keywords.e - EUINC will be changed temporarily

set TEMP_EUINC=%EUINC%
SET EUINC=%EUDIR%\bin

ex doc.exw HTML %EUDIR%
ex doc.exw TEXT %EUDIR%

ex combine.exw %EUDIR%

del %EUDIR%\doc\refman_?.doc
del %EUDIR%\doc\lib_*.doc

rem move %EUDIR%\html\readme.htm \euphoria > NUL

SET EUINC=%TEMP_EUINC%

