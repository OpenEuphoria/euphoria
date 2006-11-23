@echo creating DOCUMENTATION FILES

rem need syncolor.e and keywords.e
rem EUINC will be changed temporarily
set TEMP_EUINC=%EUINC%
SET EUINC=%EUDIR%\bin

ex doc.exw HTML \EUPHORIA
ex doc.exw TEXT \EUPHORIA

ex combine.exw \EUPHORIA

del \euphoria\doc\refman_?.doc
del \euphoria\doc\lib_*.doc

rem move \euphoria\html\readme.htm \euphoria > NUL

SET EUINC=%TEMP_EUINC%

