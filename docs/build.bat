@ echo off

..\bin\eudoc.exe -v -a manual.af -o euphoria.txt
..\bin\creolehtml.exe -A=ON -t=template.html euphoria.txt
