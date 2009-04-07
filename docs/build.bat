@ echo off

rem ..\bin\eui ..\..\Projects\eutools\eudoc.ex -v -o euphoria.txt ..\include\std\socket.e
..\bin\eui ..\..\Projects\eutools\eudoc.ex  -v -a manual.af -o euphoria.txt
..\bin\eui ..\include\creole\creolehtml.ex -A=ON -t=template.html -ohtml euphoria.txt
