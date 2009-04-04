@ echo off

rem ..\bin\exwc ..\..\Projects\eutools\eudoc.ex -v -o euphoria.txt ..\include\std\socket.e
..\bin\exwc ..\..\Projects\eutools\eudoc.ex  -v -a manual.af -o euphoria.txt
..\bin\creolehtml.exe -A=ON -t=template.html euphoria.txt
