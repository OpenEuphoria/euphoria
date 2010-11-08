[Setup]
AppName=Euphoria
AppVersion=4.0.0RC1
AppVerName=Euphoria v4.0.0RC1
AppPublisher=OpenEuphoria Group
AppPublisherURL=http://openeuphoria.org
AppSupportURL=http://openeuphoria.org
AppUpdatesURL=http://openeuphoria.org
DefaultDirName=C:\euphoria-4.0
DefaultGroupName=Euphoria 4.0
AllowNoIcons=yes
LicenseFile=..\..\license.txt
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=.\
OutputBaseFilename=euphoria-4.0.0.RC1
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
InfoBeforeFile=before.txt
InfoAfterFile=after.txt

[Types]
Name: "full"; Description: "Full installation";
Name: "standard"; Description: "Standard installation";
Name: "minimal"; Description: "Minimal installation";
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: comp_main; Description: "Core files"; Types: full standard minimal custom; Flags: fixed
Name: comp_docs; Description: "Documentation"; Types: full standard
Name: comp_tools; Description: "Euphoria related tools"; Types: full standard;
Name: comp_demos; Description: "Demonstration programs"; Types: full standard;
Name: comp_source; Description: "Source code"; Types: full;
Name: comp_tests; Description: "Unit tests"; Types: full;
Name: comp_tuts; Description: "Tutorials"; Types: full standard;

[Tasks]
Name: associate; Description: "&Associate file extensions"; Flags: unchecked
Name: update_env; Description: "&Update environment"; Flags: unchecked

[Files]
; Save all Euphoria subdirectories to backup subdirectory (can't use recursesubdirs here)
; bin
Source: "{app}\bin\*.*"; DestDir: "{code:GetBackupPath}\bin"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; include
Source: "{app}\include\*.*"; DestDir: "{code:GetBackupPath}\include"; Flags: confirmoverwrite external skipifsourcedoesntexist
Source: "{app}\include\std\*.*"; DestDir: "{code:GetBackupPath}\include\std"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
Source: "{app}\include\euphoria\*.*"; DestDir: "{code:GetBackupPath}\include\euphoria"; Flags: confirmoverwrite external skipifsourcedoesntexist
; doc
Source: "{app}\doc\*.*"; DestDir: "{code:GetBackupPath}\doc"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
Source: "{app}\docs\*.*"; DestDir: "{code:GetBackupPath}\docs"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; htm
Source: "{app}\html\*.*"; DestDir: "{code:GetBackupPath}\html"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; tutorial
Source: "{app}\tutorial\*.*"; DestDir: "{code:GetBackupPath}\tutorial"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; tests
Source: "{app}\tests\*.*"; DestDir: "{code:GetBackupPath}\tests"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; demo
Source: "{app}\demo\*.*"; DestDir: "{code:GetBackupPath}\demo"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; source
Source: "{app}\source\*.*"; DestDir: "{code:GetBackupPath}\source"; Flags: external recursesubdirs skipifsourcedoesntexist;
; top level
Source: "{app}\readme.doc"; DestDir: "{code:GetBackupPath}"; Flags: external skipifsourcedoesntexist;
Source: "{app}\readme.htm"; DestDir: "{code:GetBackupPath}"; Flags: external skipifsourcedoesntexist;
Source: "{app}\license.txt"; DestDir: "{code:GetBackupPath}"; Flags: external skipifsourcedoesntexist;
Source: "{app}\file_id.diz"; DestDir: "{code:GetBackupPath}"; Flags: external skipifsourcedoesntexist;

; Temporary Programs used to update AUTOEXEC.BAT in Windows 95, 98 and ME,
; create the docs, and euiw.exe (see [Run] section below)
Source: "..\..\bin\euiw.exe"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; We temporarily need these includes as well, but EUDIR will not have been set.
Source: "cleanbranch\include\wildcard.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\get.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\misc.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\msgbox.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\machine.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\dll.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\euphoria\keywords.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\include\euphoria\syncolor.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "cleanbranch\docs\setupae.exw"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; Files to Install
; Root
Source: "cleanbranch\file_id.diz"; DestDir: {app}; Flags: ignoreversion;
Source: "cleanbranch\license.txt"; DestDir: {app}; Flags: ignoreversion;

; Windows Binaries
Source: "..\..\bin\eub.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eubind.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eubw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\euc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eui.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\euiw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eu.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eudbg.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eu.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eudbg.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\bin\euinc.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\bin\euphoria.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main

; Windows Tools
Source: "..\..\bin\creolehtml.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eucoverage.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eudoc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eutest.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Generic Tools
Source: "cleanbranch\bin\bin.doc"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.exw"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Demos
Source: "cleanbranch\demo\*.*"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos

; Docs
Source: "..\..\build\*.pdf"; DestDir: {app}\docs\; Flags: ignoreversion; Components: comp_docs
Source: "..\..\build\html\*.*"; DestDir: {app}\docs\html\; Flags: ignoreversion; Components: comp_docs

; Includes
Source: "cleanbranch\include\*.*"; DestDir: {app}\include\; Flags: ignoreversion recursesubdirs;

; Sources
Source: "cleanbranch\source\*.*"; DestDir: {app}\source\; Flags: ignoreversion recursesubdirs; Components: comp_source

; Test
Source: "cleanbranch\tests\*.*"; DestDir: {app}\tests\; Flags: ignoreversion recursesubdirs; Components: comp_tests

; Tutorial
Source: "cleanbranch\tutorial\*.*"; DestDir: {app}\tutorial\; Flags: ignoreversion recursesubdirs; Components: comp_tuts

; Others
Source: "cleanbranch\packaging\win32\setenv.bat"; DestDir: {app}; Flags: ignoreversion; Tasks: not update_env; AfterInstall: CreateEnvBatchFile()

[INI]
; shortcut file to launch Rapid Euphoria website
Filename: {app}\RapidEuphoria.url; Section: InternetShortcut; Key: URL; String: http://www.rapideuphoria.com
Filename: {app}\OpenEuphoria.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org
Filename: {app}\EuphoriaManual.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org/docs/eu400_0001.html

[Icons]
; Icons (shortcuts) to display in the Start menu
Name: {group}\Euphoria Manual; Filename: {app}\EuphoriaManual.url
Name: {group}\Euphoria on the Web; Filename: {app}\RapidEuphoria.url
Name: {group}\Euphoria User Community (Forums and Wiki); Filename: {app}\OpenEuphoria.url
Name: {group}\Euphoria Editor; Filename: {app}\bin\ed.bat
Name: "{group}\{cm:UninstallProgram,Euphoria}"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: files; Name: {app}\RapidEuphoria.url
Type: files; Name: {app}\OpenEuphoria.url
Type: files; Name: {app}\EuphoriaManual.url

[Registry]
;set EUDIR environment variable and add to PATH on NT/2000/XP machines
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "EUDIR"; ValueData: "{app}"; Flags: uninsdeletevalue; MinVersion: 0, 3.51; Tasks: update_env
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\bin;{reg:HKCU\Environment,PATH}"; MinVersion: 0, 3.51; Tasks: update_env

;associate .exw files to be called by euiw.exe
Root: HKCR; Subkey: ".exw"; ValueType: string; ValueName: ""; ValueData: "EUWinApp"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Windows App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\euiw.exe,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euiw.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euc.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .ex files to be called by eui.exe
Root: HKCR; Subkey: ".ex"; ValueType: string; ValueName: ""; ValueData: "EUConsoleApp"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Console App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\eui.exe,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\eui.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euc.exe"" -CON ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .e, .ew files to be called by ED.bat
Root: HKCR; Subkey: ".e"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: ".ew"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile"; ValueType: string; ValueName: ""; ValueData: "Euphoria Code File"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\euinc.ico,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\ed.bat"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

[Messages]
FinishedLabel=Setup has finished installing [name] on your computer.%n%nYou can now run Euphoria .ex and .exw programs by double-clicking them, or (after reboot) by typing:%n     eui filename.ex%nor%n     euiw filename.ex/euw%non a command-line.

[Run]
;Update EUDIR and PATH in AUTOEXEC.bat for Win 95,98 and ME
Filename: "{tmp}\euiw.exe"; Description: "Update AUTOEXEC.bat"; Parameters: """{tmp}\setupae.exw"" ""{app}"""; StatusMsg: "Updating AUTOEXEC.BAT ..."; MinVersion: 4.0,0

[Code]
var
  backupDir : String;

procedure CreateEnvBatchFile();
begin
  SaveStringToFile(ExpandConstant('{app}\setenv.bat'), #13#10 + ExpandConstant('SET EUDIR={app}') + #13#10 + 'SET PATH=%EUDIR%\bin;%PATH%' + #13#10, True);
end;

function GetBackupPath(Param: String) : String;
begin
  if Length(backupDir) = 0 then
    backupDir := ExpandConstant('{app}\backup.' + GetDateTimeString('yyyymmddhhnn', #0, #0));
  Result := backupDir;
end;
