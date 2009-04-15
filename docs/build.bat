@ echo off

..\bin\eui \develop\Projects\eudoc\eudoc.ex  -v -a manual.af -o euphoria.txt
..\bin\eui ..\include\creole\creolehtml.ex -A=ON -t=template.html -ohtml euphoria.txt
