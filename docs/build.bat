@ echo off

..\bin\eui ..\source\eudoc\eudoc.ex  -v -a manual.af -o euphoria.txt
..\bin\eui ..\source\eudoc\creole\creolehtml.ex -A=ON -t=template.html -ohtml euphoria.txt
