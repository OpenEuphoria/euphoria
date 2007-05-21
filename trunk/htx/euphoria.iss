; -- Inno Setup script to install Euphoria by Rapid Deployment Software
; --
; --------------------------------------------------------------------------------
; -- Euphoria can be found as http://www.rapideuphoria.com
; -- The Inno Setup compiler can be found at http://www.innosetup.com and is free
; --
; --------------------------------------------------------------------------------
; -- Created by Alberto Gonzalez (of Nomadic Soul Concepts - NomSCon)
; -- EMail: al@nomscon.com
; --

[Setup]
AppName=Euphoria
AppVersion=3.0
AppVerName=Euphoria v3.0.3
AppPublisher=Rapid Deployment Software
AppPublisherURL=http://www.rapideuphoria.com
AppSupportURL=http://www.rapideuphoria.com
AppUpdatesURL=http://www.rapideuphoria.com
DefaultDirName=C:\EUPHORIA
DefaultGroupName=Euphoria
AllowNoIcons=yes
;LicenseFile=License.txt
; uncomment the following line if you want your installation to run on NT 3.51 too.
;MinVersion=4,3.51
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=..\Setup
OutputBaseFilename=e30setup
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
InfoBeforeFile=c:\eusvn\trunk\htx\before.txt
InfoAfterFile=c:\eusvn\trunk\htx\after.txt
Uninstallable=no

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

;[Components]
;Name: "main"; Description: "Core files (Interpreter and Translator)"; Types: full; Flags: fixed
;Name: "docs"; Description: "Documentation and Tutorial"; Types: full; Flags: fixed
;Name: "demos"; Description: "Demonstration programs"; Types: full; Flags: fixed
;Name; "source"; Description: "Source code"; Types: full; Flags: fixed
;[Tasks]
;Name: "associate"; Description: "&Associate file extensions";

[Dirs]
Name: "{app}\backup"; Flags: deleteafterinstall
Name: "{app}\HTML";
Name: "{app}\DOC";

[Files]
; Save all Euphoria subdirectories to backup subdirectory (can't use recursesubdirs here)
; bin
Source: "{app}\bin\*.*"; DestDir: "{app}\backup\bin"; Flags: confirmoverwrite external skipifsourcedoesntexist
; include
Source: "{app}\include\*.*"; DestDir: "{app}\backup\include"; Flags: confirmoverwrite external skipifsourcedoesntexist
; doc
Source: "{app}\doc\*.*"; DestDir: "{app}\backup\doc"; Flags: confirmoverwrite external skipifsourcedoesntexist
; htm
Source: "{app}\html\*.*"; DestDir: "{app}\backup\html"; Flags: confirmoverwrite external skipifsourcedoesntexist
; tutorial
Source: "{app}\tutorial\*.*"; DestDir: "{app}\backup\tutorial"; Flags: confirmoverwrite external skipifsourcedoesntexist
; demo
Source: "{app}\demo\*.*"; DestDir: "{app}\backup\demo"; Flags: confirmoverwrite external skipifsourcedoesntexist
; demo\dos32
Source: "{app}\demo\dos32\*.*"; DestDir: "{app}\backup\demo\dos32"; Flags: confirmoverwrite external skipifsourcedoesntexist
; demo\win32
Source: "{app}\demo\win32\*.*"; DestDir: "{app}\backup\demo\win32"; Flags: external skipifsourcedoesntexist
; demo\langwar
Source: "{app}\demo\langwar\*.*"; DestDir: "{app}\backup\demo\langwar"; Flags: external skipifsourcedoesntexist
; demo\bench
Source: "{app}\demo\bench\*.*"; DestDir: "{app}\backup\demo\bench"; Flags: external skipifsourcedoesntexist;
; source
Source: "{app}\source\*.*"; DestDir: "{app}\backup\source"; Flags: external skipifsourcedoesntexist;
; top level
Source: "{app}\readme.doc"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;
Source: "{app}\readme.htm"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;
Source: "{app}\License.txt"; DestDir: "{app}\backup"; Flags: external skipifsourcedoesntexist;

; Temporary Programs used to update AUTOEXEC.BAT in Windows 95, 98 and ME,
; create the docs, and exwc.exe (see [Run] section below)
Source: c:\eusvn\trunk\bin\exw.exe; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\bin\makecon.exw; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\htx\setupae.exw; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;  MinVersion: 4.0,0
Source: c:\eusvn\trunk\htx\doc.exw; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\htx\docgen.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\htx\html.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\htx\text.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\htx\combine.exw; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; We temporarily need these includes as well, but EUDIR will not have been set.
Source: c:\eusvn\trunk\include\wildcard.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\include\get.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\include\misc.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\include\msgbox.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\include\machine.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\include\dll.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\bin\keywords.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;
Source: c:\eusvn\trunk\bin\syncolor.e; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; Files to Install
;Root
Source: C:\EUSVN\TRUNK\FILE_ID.DIZ; DestDir: {app}; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\License.txt; DestDir: {app}; Flags: ignoreversion;
;BIN
Source: C:\EUSVN\TRUNK\BIN\EX.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EXW.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\BACKEND.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\BACKENDW.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\SYNCOLOR.E; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\BIN.DOC; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\KEYWORDS.E; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ED.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\LINES.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ASCII.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: "C:\EUSVN\TRUNK\BIN\KEY.EX"; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\GURU.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\WHERE.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\SEARCH.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EPRINT.EX; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\LINES.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\GURU.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EPRINT.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ED.BAT; DestDir: {app}\BIN\; Flags: ignoreversion; MinVersion: 0,4.0
Source: C:\EUSVN\TRUNK\BIN\OLDED.BAT; DestDir: {app}\BIN\; DestName: ed.bat; Flags: ignoreversion; MinVersion: 4.0,0
Source: C:\EUSVN\TRUNK\BIN\CDGURU.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\SEARCH.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ASCII.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\WHERE.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: "C:\EUSVN\TRUNK\BIN\KEY.BAT"; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\MAKE31.EXW; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\MAKECON.EXW; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EUINC.ICO; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EC.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ECW.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\LE23P.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\CWC.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\CWSTUB.EXE; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\LIBALLEG.A; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\BIND.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\BINDW.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\SHROUD.BAT; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EC.A; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EC.LIB; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ECFASTFP.LIB; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ECW.LIB; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ECWB.LIB; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\ECWL.LIB; DestDir: {app}\BIN\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\BIN\EUPHORIA.ICO; DestDir: {app}\BIN\; Flags: ignoreversion;

;DEMO
Source: C:\EUSVN\TRUNK\DEMO\*.ex; DestDir: {app}\DEMO\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\*.exu; DestDir: {app}\DEMO\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\*.doc; DestDir: {app}\DEMO\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\WIN32\*.*; DestDir: {app}\DEMO\WIN32; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\DOS32\*.*; DestDir: {app}\DEMO\DOS32; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\LANGWAR\*.*; DestDir: {app}\DEMO\LANGWAR; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\DEMO\BENCH\*.*; DestDir: {app}\DEMO\BENCH; Flags: ignoreversion;
;HTX
Source: C:\EUSVN\TRUNK\HTX\*.HTX; DestDir: {tmp}; Flags: ignoreversion;
;INCLUDE
Source: C:\EUSVN\TRUNK\INCLUDE\*.E; DestDir: {app}\INCLUDE\; Flags: ignoreversion;
Source: C:\EUSVN\TRUNK\INCLUDE\EUPHORIA.H; DestDir: {app}\INCLUDE\; Flags: ignoreversion;
;SOURCE
Source: C:\EUSVN\TRUNK\source\*.*; DestDir: {app}\SOURCE\; Flags: ignoreversion;
;TUTORIAL
Source: C:\EUSVN\TRUNK\TUTORIAL\*.*; DestDir: {app}\TUTORIAL\; Flags: ignoreversion;

[INI]
; shortcut file to launch Rapid Euphoria website
Filename: {app}\RapidEuphoria.url; Section: InternetShortcut; Key: URL; String: http://www.rapideuphoria.com

[Icons]
; Icons (shortcuts) to display in the Start menu
Name: {group}\Euphoria Manual; Filename: {app}\html\refman.htm
Name: {group}\Euphoria on the Web; Filename: {app}\RapidEuphoria.url
Name: {group}\Euphoria (Win); Filename: {app}\BIN\EXW.EXE
Name: {group}\Euphoria (Dos); Filename: {app}\BIN\EX.EXE
Name: {group}\Euphoria Editor; Filename: {app}\BIN\ED.bat


[UninstallDelete]
Type: files; Name: {app}\RapidEuphoria.url

[Registry]
;set EUDIR environment variable and add to PATH on NT/2000/XP machines
ROOT: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "EUDIR"; ValueData: "{app}"; Flags: uninsdeletevalue; MinVersion: 0, 3.51
ROOT: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\BIN;{reg:HKCU\Environment,PATH}"; MinVersion: 0, 3.51

;associate .exw files to be called by EXW.exe
Root: HKCR; Subkey: ".exw"; ValueType: string; ValueName: ""; ValueData: "EUWinApp"; Flags: uninsdeletevalue createvalueifdoesntexist
Root: HKCR; Subkey: "EUWinApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Windows App"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUWinApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\BIN\EXW.EXE,0"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUWinApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\BIN\EXW.EXE"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist

;associate .ex files to be called by EX.exe
Root: HKCR; Subkey: ".ex"; ValueType: string; ValueName: ""; ValueData: "EUDOSApp"; Flags: uninsdeletevalue createvalueifdoesntexist
Root: HKCR; Subkey: "EUDOSApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria DOS App"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUDOSApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\BIN\EXW.EXE,0"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUDOSApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\BIN\EX.EXE"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist

;associate .e, .ew files to be called by ED.bat
Root: HKCR; Subkey: ".e"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist
Root: HKCR; Subkey: ".ew"; ValueType: string; ValueName: ""; ValueData: "EUCodeFile"; Flags: uninsdeletevalue createvalueifdoesntexist
Root: HKCR; Subkey: "EUCodeFile"; ValueType: string; ValueName: ""; ValueData: "Euphoria Code File"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUCodeFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\BIN\EuInc.ico,0"; Flags: uninsdeletekey createvalueifdoesntexist
Root: HKCR; Subkey: "EUCodeFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\BIN\ED.BAT"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist

[Messages]
FinishedLabel=Setup has finished installing [name] on your computer.%n%nYou can now run Euphoria .ex and .exw programs by double-clicking them, or (after reboot) by typing:%n     ex filename.ex%nor%n     exw filename.exw%non a command-line.

[Run]
;Generate DOCS, and update EUDIR and PATH in AUTOEXEC.bat for Win 95,98 and ME
Filename: "{tmp}\exw.exe"; Description: "Generate Documentation Files as HTML"; Parameters: "{tmp}\doc.exw HTML {app}"; StatusMsg: "Generating HTML documentation files ...";
Filename: "{tmp}\exw.exe"; Description: "Generate Documentation Files as plain text"; Parameters: "{tmp}\doc.exw TEXT {app}"; StatusMsg: "Generating plain text documentation files ...";
Filename: "{tmp}\exw.exe"; Description: "Combine Documentation Files"; Parameters: "{tmp}\combine.exw {app}"; StatusMsg: "Combining documentation files ...";
Filename: "{tmp}\exw.exe"; Description: "Create exwc.exe"; Parameters: "{tmp}\makecon.exw ""{app}"""; StatusMsg: "Making exwc.exe ...";
Filename: "{tmp}\exw.exe"; Description: "Update AUTOEXEC.bat"; Parameters: "{tmp}\setupae.exw {app}"; StatusMsg: "Updating AUTOEXEC.BAT ..."; MinVersion: 4.0,0

