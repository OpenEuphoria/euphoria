; -- Inno Setup script to install Euphoria by Rapid Deployment Software

[Setup]
AppName=Euphoria
AppVersion=4.0
AppVerName=Euphoria v4.0
AppPublisher=Rapid Deployment Software
AppPublisherURL=http://www.rapideuphoria.com
AppSupportURL=http://www.rapideuphoria.com
AppUpdatesURL=http://www.rapideuphoria.com
DefaultDirName=C:\euphoria
DefaultGroupName=Euphoria 4.0
AllowNoIcons=yes
LicenseFile=..\..\license.txt
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=.\
OutputBaseFilename=euphoria_40
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
InfoBeforeFile=before.txt
InfoAfterFile=after.txt

[Types]
Name: "full"; Description: "Full installation";
Name: "standard"; Description: "Standard installation";
Name: "windows"; Description: "Windows only installation";
Name: "dos"; Description: "DOS only installation";
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: comp_main; Description: "Core files"; Types: full standard custom; Flags: fixed
Name: comp_win; Description: "Windows Interpreter and Translator"; Types: full windows standard;
Name: comp_dos; Description: "DOS Interpreter and Translator"; Types: full dos standard;
Name: comp_tools; Description: "Euphoria related tools"; Types: full standard windows dos;
Name: comp_demos; Description: "Demonstration programs"; Types: full standard windows dos;
Name: comp_source; Description: "Source code"; Types: full;
Name: comp_tests; Description: "Unit tests"; Types: full standard windows dos;

[Tasks]
Name: associate; Description: "&Associate file extensions"; Flags: unchecked
Name: update_env; Description: "&Update environment"; Flags: unchecked

;Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
;Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

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
; create the docs, and exwc.exe (see [Run] section below)
Source: "..\..\bin\exw.exe"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

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

; DOS Binaries
Source: "..\..\bin\ex.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\backend.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\ec.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\le23p.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\cwc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\cwstub.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "..\..\bin\ec.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "cleanbranch\bin\bind.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos
Source: "cleanbranch\bin\shroud.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos

; DOS Tools
Source: "cleanbranch\bin\eutestd.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_dos and comp_tools
Source: "cleanbranch\bin\ed.bat"; DestDir: {app}\bin\; Flags: ignoreversion; MinVersion: 0,4.0; Components: comp_dos and comp_tools

; Windows Binaries
Source: "..\..\bin\ecw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "..\..\bin\exw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "..\..\bin\exwc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "..\..\bin\backendw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "..\..\bin\ecw.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "cleanbranch\bin\bindw.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "cleanbranch\bin\shroudw.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "cleanbranch\bin\euinc.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win
Source: "cleanbranch\bin\euphoria.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win

; Windows Tools
Source: "cleanbranch\bin\eutest.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_win and comp_tools
Source: "cleanbranch\bin\edw.bat"; DestDir: {app}\bin\; Flags: ignoreversion; MinVersion: 0,4.0; Components: comp_win and comp_tools

; Generic Tools
Source: "cleanbranch\bin\bin.doc"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\ed.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\lines.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\ascii.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\key.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\guru.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\where.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\search.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\eprint.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\lines.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\guru.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\eprint.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\cdguru.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\search.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\ascii.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\where.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\key.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\eutest.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\make31.exw"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
;Source: "cleanbranch\bin\ecp.dat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\buildcpdb.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Demos
Source: "cleanbranch\demo\*.ex"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos
Source: "cleanbranch\demo\*.exw"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist; Components: comp_demos
Source: "cleanbranch\demo\*.exd"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist; Components: comp_demos
Source: "cleanbranch\demo\*.doc"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos

; Includes
Source: "cleanbranch\include\*.e"; DestDir: {app}\include\; Flags: ignoreversion recursesubdirs;
Source: "cleanbranch\include\euphoria.h"; DestDir: {app}\include\; Flags: ignoreversion;

; Sources
Source: "cleanbranch\source\*.*"; Excludes: up.bat; DestDir: {app}\source\; Flags: ignoreversion; Components: comp_source
Source: "cleanbranch\source\codepage\*.*"; DestDir: {app}\bin\codepage; Flags: ignoreversion;

; Test
Source: "cleanbranch\tests\*.*"; DestDir: {app}\tests\; Flags: ignoreversion recursesubdirs; Components: comp_tests

; Tutorial
Source: "cleanbranch\tutorial\*.*"; DestDir: {app}\tutorial\; Flags: ignoreversion; Components: comp_demos

; Others
Source: "cleanbranch\packaging\win32\setenv.bat"; DestDir: {app}; Flags: ignoreversion; Tasks: not update_env; AfterInstall: CreateEnvBatchFile()

[INI]
; shortcut file to launch Rapid Euphoria website
Filename: {app}\RapidEuphoria.url; Section: InternetShortcut; Key: URL; String: http://www.rapideuphoria.com
Filename: {app}\OpenEuphoria.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org
Filename: {app}\EuphoriaManual.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org/docs/

[Icons]
; Icons (shortcuts) to display in the Start menu
Name: {group}\Euphoria Manual; Filename: {app}\EuphoriaManual.url
Name: {group}\Euphoria on the Web; Filename: {app}\RapidEuphoria.url
Name: {group}\Euphoria User Community (Forums and Wiki); Filename: {app}\OpenEuphoria.url
Name: {group}\Euphoria (Win); Filename: {app}\bin\exw.exe; Components: comp_win
Name: {group}\Euphoria (Win Console); Filename: {app}\bin\exwc.exe; Components: comp_win
Name: {group}\Euphoria (Dos); Filename: {app}\bin\ex.exe; Components: comp_dos
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

;associate .exw files to be called by EXW.exe
Root: HKCR; Subkey: ".exw"; ValueType: string; ValueName: ""; ValueData: "EUWinApp"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Windows App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\exw.exe,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\exw.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .ex files to be called by EXWC.exe
Root: HKCR; Subkey: ".ex"; ValueType: string; ValueName: ""; ValueData: "EUConsoleApp"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Console App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\exw.exe,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\exwc.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .exd files to be called by EX.exe
Root: HKCR; Subkey: ".exd"; ValueType: string; ValueName: ""; ValueData: "EUDosApp"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUDosApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Console App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUDosApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\exw.exe,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUDosApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\ex.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .e, .ew files to be called by ED.bat
Root: HKCR; Subkey: ".e"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: ".ew"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile"; ValueType: string; ValueName: ""; ValueData: "Euphoria Code File"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\euinc.ico,0"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUCodeFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\ed.bat"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

[Messages]
FinishedLabel=Setup has finished installing [name] on your computer.%n%nYou can now run Euphoria .ex, .exw and .exd programs by double-clicking them, or (after reboot) by typing:%n     ex filename.exd%nor%n     exw/exwc filename.ex/exw%non a command-line.

[Run]
;Update EUDIR and PATH in AUTOEXEC.bat for Win 95,98 and ME
Filename: "{tmp}\exw.exe"; Description: "Update AUTOEXEC.bat"; Parameters: """{tmp}\setupae.exw"" ""{app}"""; StatusMsg: "Updating AUTOEXEC.BAT ..."; MinVersion: 4.0,0

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

