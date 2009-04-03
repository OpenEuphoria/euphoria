@ echo off

..\bin\eudoc.exe -v -a eu40.af -o euphoria.txt
..\bin\creolehtml.exe -A=ON -t=template.html -o=html euphoria.txt
