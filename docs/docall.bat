@echo off
echo creating DOCUMENTATION FILES

rem need syncolor.e and keywords.e - EUINC will be changed temporarily

set TEMP_EUINC=%EUINC%
SET EUINC=..\bin;..\include

eui doc.exw HTML ..

rem these files are only needed to update RDS Web site

SET EUINC=%TEMP_EUINC%

