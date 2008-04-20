@echo creating DOCUMENTATION FILES

rem need syncolor.e and keywords.e - EUINC will be changed temporarily

set TEMP_EUINC=%EUINC%
SET EUINC=..\bin;..\include

exwc doc.exw HTML ..
exwc doc.exw TEXT ..

exwc combine.exw ..

rem these files are only needed to update RDS Web site
del ..\doc\refman_?.doc
del ..\doc\lib_*.doc

SET EUINC=%TEMP_EUINC%

