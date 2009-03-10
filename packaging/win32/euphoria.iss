; -- Inno Setup script to install Euphoria by Rapid Deployment Software

[Setup]
AppName=Euphoria
AppVersion=4.0a3
AppVerName=Euphoria v4.0a3
AppPublisher=Rapid Deployment Software
AppPublisherURL=http://www.rapideuphoria.com
AppSupportURL=http://www.rapideuphoria.com
AppUpdatesURL=http://www.rapideuphoria.com
DefaultDirName=C:\euphoria40
DefaultGroupName=Euphoria 4.0
AllowNoIcons=yes
LicenseFile=..\..\license.txt
; uncomment the following line if you want your installation to run on NT 3.51 too.
;MinVersion=4,3.51
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=.\
OutputBaseFilename=euphoria_40a3
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
InfoBeforeFile=before.txt
InfoAfterFile=after.txt
Uninstallable=yes

[Types]
Name: "full"; Description: "Full installation";
Name: "standard"; Description: "Standard installation";
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: comp_main; Description: "Core files (Interpreter and Translator)"; Types: full standard custom; Flags: fixed
Name: comp_tools; Description: "Euphoria related tools"; Types: full standard;
Name: comp_docs; Description: "Documentation and Tutorial"; Types: full standard;
Name: comp_demos; Description: "Demonstration programs"; Types: full standard;
Name: comp_source; Description: "Source code"; Types: full;
Name: comp_tests; Description: "Unit tests"; Types: full standard;

[Tasks]
Name: associate; Description: "&Associate file extensions";
;Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
;Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Dirs]
Name: "{app}\backup"; Flags: deleteafterinstall

[Files]
; Save all Euphoria subdirectories to backup subdirectory (can't use recursesubdirs here)
; bin
Source: "{app}\bin\*.*"; DestDir: "{app}\backup\bin"; Flags: confirmoverwrite external skipifsourcedoesntexist
; include
Source: "{app}\include\*.*"; DestDir: "{app}\backup\include"; Flags: confirmoverwrite external skipifsourcedoesntexist
Source: "{app}\include\std\*.*"; DestDir: "{app}\backup\include\std"; Flags: confirmoverwrite external skipifsourcedoesntexist
Source: "{app}\include\euphoria\*.*"; DestDir: "{app}\backup\include\euphoria"; Flags: confirmoverwrite external skipifsourcedoesntexist
; doc
Source: "{app}\doc\*.*"; DestDir: "{app}\backup\doc"; Flags: confirmoverwrite external skipifsourcedoesntexist
Source: "{app}\docs\*.*"; DestDir: "{app}\backup\docs"; Flags: confirmoverwrite external skipifsourcedoesntexist
; htm
Source: "{app}\html\*.*"; DestDir: "{app}\backup\html"; Flags: confirmoverwrite external skipifsourcedoesntexist
; tutorial
Source: "{app}\tutorial\*.*"; DestDir: "{app}\backup\tutorial"; Flags: confirmoverwrite external skipifsourcedoesntexist
; demo
Source: "{app}\demo\*.*"; DestDir: "{app}\backup\demo"; Flags: confirmoverwrite external recursesubdirs skipifsourcedoesntexist
; source
Source: "{app}\source\*.*"; DestDir: "{app}\backup\source"; Flags: external recursesubdirs skipifsourcedoesntexist;
; top level
Source: "{app}\readme.doc"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;
Source: "{app}\readme.htm"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;
Source: "{app}\license.txt"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;
Source: "{app}\file_id.diz"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;

; Temporary Programs used to update AUTOEXEC.BAT in Windows 95, 98 and ME,
; create the docs, and exwc.exe (see [Run] section below)
Source: "..\..\bin\exw.exe"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; We temporarily need these includes as well, but EUDIR will not have been set.
Source: "..\..\include\wildcard.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\get.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\misc.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\msgbox.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\machine.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\dll.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\euphoria\keywords.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: "..\..\include\euphoria\syncolor.e"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; Files to Install
;Root
Source: "..\..\file_id.diz"; DestDir: {app}; Flags: ignoreversion;
Source: "..\..\license.txt"; DestDir: {app}; Flags: ignoreversion;
;BIN
Source: "..\..\bin\ex.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\exw.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\exwc.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\backend.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\backendw.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\bin.doc"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_docs
Source: "..\..\bin\ed.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\lines.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\ascii.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\key.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\guru.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\where.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\search.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eprint.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\lines.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\guru.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eprint.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\ed.bat"; DestDir: {app}\bin\; Flags: ignoreversion; MinVersion: 0,4.0; Components: comp_tools
Source: "..\..\bin\olded.bat"; DestDir: {app}\bin\; DestName: ed.bat; Flags: ignoreversion; MinVersion: 4.0,0;  Components: comp_tools
Source: "..\..\bin\cdguru.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\search.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\ascii.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\where.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\key.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eutest.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eutest.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eutestd.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\make31.exw"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\makecon.exw"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\euinc.ico"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\ec.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\ecw.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\le23p.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\cwc.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\cwstub.exe"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\bind.bat"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\bindw.bat"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\shroud.bat"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\ec.lib"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\ecw.lib"; DestDir: {app}\bin\; Flags: ignoreversion;
Source: "..\..\bin\euphoria.ico"; DestDir: {app}\bin\; Flags: ignoreversion;

;DEMO
Source: "..\..\demo\*.ex"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos
Source: "..\..\demo\*.exw"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos
Source: "..\..\demo\*.exd"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist; Components: comp_demos
Source: "..\..\demo\*.doc"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos

;INCLUDE
Source: ..\..\include\*.e; DestDir: {app}\include\; Flags: ignoreversion recursesubdirs;
Source: "..\..\include\euphoria.h"; DestDir: {app}\include\; Flags: ignoreversion;

;SOURCE
Source: "..\..\source\*.*"; DestDir: {app}\source\; Flags: ignoreversion; Components: comp_source
Source: "..\..\source\codepage\*.*"; DestDir: {app}\source\codepage; Flags: ignoreversion; Components: comp_source

;TESTS
Source: "..\..\tests\*.*"; DestDir: {app}\tests\; Flags: ignoreversion recursesubdirs; Components: comp_tests

;TUTORIAL
Source: "..\..\tutorial\*.*"; DestDir: {app}\tutorial\; Flags: ignoreversion; Components: comp_demos

;DOCS
Source: "..\..\docs\*.txt"; DestDir: {app}\docs\; Flags: ignoreversion; Components: comp_docs

[INI]
; shortcut file to launch Rapid Euphoria website
Filename: {app}\RapidEuphoria.url; Section: InternetShortcut; Key: URL; String: http://www.rapideuphoria.com
Filename: {app}\OpenEuphoria.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.com

[Icons]
; Icons (shortcuts) to display in the Start menu
Name: {group}\Euphoria Manual; Filename: {app}\html\refman.htm
Name: {group}\Euphoria on the Web; Filename: {app}\RapidEuphoria.url
Name: {group}\Euphoria User Community (Forums and Wiki); Filename: {app}\OpenEuphoria.url
Name: {group}\Euphoria (Win); Filename: {app}\bin\exw.exe
Name: {group}\Euphoria (Win Console); Filename: {app}\bin\exwc.exe
Name: {group}\Euphoria (Dos); Filename: {app}\bin\ex.exe
Name: {group}\Euphoria Editor; Filename: {app}\bin\ed.bat

[UninstallDelete]
Type: files; Name: {app}\RapidEuphoria.url
Type: files; Name: {app}\OpenEuphoria.url

[Registry]
;set EUDIR environment variable and add to PATH on NT/2000/XP machines
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "EUDIR"; ValueData: "{app}"; Flags: uninsdeletevalue; MinVersion: 0, 3.51
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\bin;{reg:HKCU\Environment,PATH}"; MinVersion: 0, 3.51

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
FinishedLabel=Setup has finished installing [name] on your computer.%n%nYou can now run Euphoria .ex and .exw programs by double-clicking them, or (after reboot) by typing:%n     ex filename.ex%nor%n     exw filename.exw%non a command-line.

[Run]
;Update EUDIR and PATH in AUTOEXEC.bat for Win 95,98 and ME
Filename: "{tmp}\exw.exe"; Description: "Update AUTOEXEC.bat"; Parameters: """{tmp}\setupae.exw"" ""{app}"""; StatusMsg: "Updating AUTOEXEC.BAT ..."; MinVersion: 4.0,0

