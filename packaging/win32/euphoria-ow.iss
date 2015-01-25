; When making changes to this file, remember to make a similar change to
; euphoria.iss

; The following files all must be
; changed when changing the patch version,
; minor version or major version:
; 1. /source/version_info.rc
; 2. /packaging/win32/euphoria.iss
; 3. /packaging/win32/euphoria-ow.iss
; 4. /tests/t_condcmp.e
; 5. /source/version.h
; 6. /docs/refman_2.txt (Euphoria Version Definitions)

[Setup]
AppName=Euphoria
AppVersion=4.0.6
AppVerName=Euphoria v4.0.6
AppPublisher=OpenEuphoria Group
AppPublisherURL=http://openeuphoria.org
AppSupportURL=http://openeuphoria.org
AppUpdatesURL=http://openeuphoria.org
DefaultDirName=c:\euphoria
DefaultGroupName=Euphoria
AllowNoIcons=yes
LicenseFile=..\..\license.txt
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=.\
OutputBaseFilename=euphoria-4.0.6-ow
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
ChangesEnvironment=yes
InfoBeforeFile=before.txt
InfoAfterFile=after.txt
; set the minimum environment required to 
; Windows 95 Original Equipment Manufacterer Service Release 2.5 (see ticket 665)
MinVersion=4.0.1212,

[Types]
Name: "full"; Description: "Full installation";
Name: "standard"; Description: "Standard installation";
Name: "minimal"; Description: "Minimal installation";
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: comp_main; Description: "Core files"; Types: full standard minimal custom; Flags: fixed
Name: comp_ow; Description: "OpenWatcom"; Types: full standard;
Name: comp_docs; Description: "Documentation"; Types: full standard
Name: comp_tools; Description: "Euphoria related tools"; Types: full standard;
Name: comp_demos; Description: "Demonstration programs"; Types: full standard;
Name: comp_source; Description: "Source code"; Types: full;
Name: comp_tests; Description: "Unit tests"; Types: full;
Name: comp_tuts; Description: "Tutorials"; Types: full standard;

[Tasks]
Name: associate; Description: "&Associate file extensions";
Name: update_env; Description: "&Update environment";

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
Source: "cleanbranch\source\autoexec_update.exw"; DestDir: {tmp}; Flags: ignoreversion deleteafterinstall;

; Files to Install
; Root
Source: "cleanbranch\file_id.diz"; DestDir: {app}; Flags: ignoreversion;
Source: "cleanbranch\license.txt"; DestDir: {app}; Flags: ignoreversion;

; Windows Binaries
Source: "..\..\bin\eu.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eu.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eub.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eubind.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eubw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\euc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eudbg.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eudbg.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eui.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main; AfterInstall: InstallEuCfg
Source: "..\..\bin\euiw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\bin\eushroud.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\source\eufile.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\source\euphoria.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main

; Windows Tools
Source: "..\..\bin\creole.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eucoverage.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eudis.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eudist.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eudoc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\euloc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\bin\eutest.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Generic Tools
Source: "cleanbranch\bin\*.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.exw"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Demos
Source: "cleanbranch\demo\*.*"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos

; Docs
Source: "..\..\source\build\*.pdf"; DestDir: {app}\docs\; Flags: ignoreversion; Components: comp_docs
Source: "..\..\source\build\html\*.*"; DestDir: {app}\docs\html\; Flags: ignoreversion recursesubdirs; Components: comp_docs

; Includes
Source: "cleanbranch\include\*.*"; DestDir: {app}\include\; Flags: ignoreversion recursesubdirs; Components: comp_main

; Sources
Source: "..\..\source\*.*"; DestDir: {app}\source\; Flags: ignoreversion; Components: comp_source
Source: "..\..\source\codepage\*.*"; DestDir: {app}\source\; Flags: ignoreversion; Components: comp_source
Source: "..\..\source\pcre\*.*"; DestDir: {app}\source\pcre\; Flags: ignoreversion; Components: comp_source

; Test
Source: "cleanbranch\tests\*.*"; DestDir: {app}\tests\; Flags: ignoreversion recursesubdirs; Components: comp_tests

; Tutorial
Source: "cleanbranch\tutorial\*.*"; DestDir: {app}\tutorial\; Flags: ignoreversion recursesubdirs; Components: comp_tuts

; Others
Source: "cleanbranch\packaging\win32\setenv-ow.bat"; DestDir: {app}; Flags: ignoreversion; Tasks: not update_env; AfterInstall: CreateEnvBatchFile()

; OpenWatcom
Source: "\Development\WATCOM-OEBUNDLE\*.*"; DestDir: {app}\watcom; Flags: ignoreversion recursesubdirs; Components: comp_ow; 

[INI]
; shortcut file to launch Rapid Euphoria website
Filename: {app}\RapidEuphoria.url; Section: InternetShortcut; Key: URL; String: http://www.rapideuphoria.com
Filename: {app}\OpenEuphoria.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org
Filename: {app}\EuphoriaManual.url; Section: InternetShortcut; Key: URL; String: http://openeuphoria.org/docs/index.html

[Icons]
; Icons (shortcuts) to display in the Start menu
Name: {group}\Euphoria Manual in HTML; Filename: {app}\docs\html\index.html; Components: comp_docs
Name: {group}\Euphoria Manual in PDF; Filename: {app}\docs\euphoria.pdf; Components: comp_docs
Name: {group}\Euphoria Manual on the Web; Filename: {app}\EuphoriaManual.url
Name: {group}\Euphoria Website;  Filename: {app}\RapidEuphoria.url
Name: {group}\Euphoria User Community (Forums and Wiki);  Filename: {app}\OpenEuphoria.url
Name: "{group}\{cm:UninstallProgram,Euphoria}"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: files; Name: {app}\RapidEuphoria.url
Type: files; Name: {app}\OpenEuphoria.url
Type: files; Name: {app}\EuphoriaManual.url

[Registry]
;set EUDIR environment variable and add to PATH on NT/2000/XP machines
;Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "EUDIR"; ValueData: "{app}"; MinVersion: 0, 3.51; Tasks: update_env
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "PATH"; ValueData: "{app}\bin;{reg:HKCU\Environment,PATH}"; MinVersion: 0, 3.51; Tasks: update_env
Root: HKCU; SubKey: "Environment"; ValueType: string; ValueName: "INCLUDE"; ValueData: "{app}\watcom\h;{app}\watcom\h\nt"; Flags: uninsdeletevalue; MinVersion: 0, 3.51; Tasks: update_env; Components: comp_ow;
Root: HKCU; Subkey: "Environment"; ValueType: string; ValueName: "WATCOM"; ValueData: "{app}\watcom"; Flags: uninsdeletevalue; MinVersion: 0, 3.51; Tasks: update_env; Components: comp_ow;

;associate .exw files to be called by euiw.exe
Root: HKCR; Subkey: ".exw"; ValueType: string; ValueName: ""; ValueData: "EUWinApp"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Windows App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\eufile.ico"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euiw.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euc.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .ex files to be called by eui.exe
Root: HKCR; Subkey: ".ex"; ValueType: string; ValueName: ""; ValueData: "EUConsoleApp"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Console App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\eufile.ico"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\eui.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\euc.exe"" -con ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;create an icon link for .e files
Root: HKCR; Subkey: ".e"; ValueType: string; ValueName: ""; ValueData: "EUInc"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUInc"; ValueType: string; ValueName: ""; ValueData: "Euphoria Include File"; Flags: deletekey uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUInc\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\eufile.ico"; Flags: deletekey uninsdeletekey createvalueifdoesntexist; Tasks: associate

;create an icon link for .ew files
Root: HKCR; Subkey: ".ew"; ValueType: string; ValueName: ""; ValueData: "EUInc"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate

[Messages]
FinishedLabel=Setup has finished installing [name] on your computer.%n%nYou can now run Euphoria .ex and .exw programs by double-clicking them, or (after reboot) by typing:%n     eui filename.ex%nor%n     euiw filename.ex/euw%non a command-line.

[Run]
;Update EUDIR and PATH in AUTOEXEC.bat for Win 95,98 and ME
Filename: "{tmp}\euiw.exe"; Description: "Update AUTOEXEC.bat"; Parameters: """{tmp}\autoexec_update.exw"" ""{app}"""; StatusMsg: "Updating AUTOEXEC.BAT ..."; MinVersion: 4.0,0

[Code]
var
	backupDir : String;

procedure CreateEnvBatchFile();
begin
	SaveStringToFile(ExpandConstant('{app}\setenv-ow.bat'), #13#10 + 

		ExpandConstant('SET EUDIR={app}') + #13#10 + 
		ExpandConstant('SET WATCOM={app}\watcom') + #13#10 + 
		'SET PATH=%EUDIR%\bin;%WATCOM%\binw;%WATCOM%\binnt;%PATH%' + #13#10 + 
		'SET INCLUDE=%WATCOM%\h;%WATCOM%\h\nt' + #13#10, 
		True);
end;

function GetBackupPath(Param: String) : String;
begin
	if Length(backupDir) = 0 then
		backupDir := ExpandConstant('{app}\backup.' + GetDateTimeString('yyyymmddhhnn', #0, #0));
	 Result := backupDir;
end;
function generateEuCfgString() : String;
var
  euCfgFname : String;
  incLine : String;
begin
  euCfgFName := ExpandConstant('{app}\bin\eu.cfg');
   incLine := ExpandConstant('-i {app}\include');
  Result := #13#10 + '[all]' + #13#10 + incLine + #13#10;
end;

procedure InstallEuCfg();
var
  euCfgFname : String;
  incLine : String;

begin
  incLine := ExpandConstant('-i {app}\include');
  euCfgFname := ExpandConstant('{app}\bin\eu.cfg');

  if FileExists(euCfgFname) = False then
    begin
      SaveStringToFile(euCfgFname, generateEuCfgString(), False);
    end
  else
    begin
      if MsgBox('An eu.cfg file exists already. It should really contain' + #13#10 +
                 incLine + #13#10 +
                 'Should the installer append this line?', 
                 mbConfirmation, MB_YESNO or MB_DEFBUTTON1) = IDYES
      then
        begin
          SaveStringToFile(euCfgFname, generateEuCfgString(), True);
        end
      else
        MsgBox('Please ensure ' + euCfgFname + ' contains:' + #13#10 +
               incLine, mbInformation, MB_OK);
    end;
end;

function InitializeUninstall(): Boolean;
var euCfgFname : String;
var euCfgContents_theoretical : String;
var euCfgContents_tested : String;
var path : String;
var include : String;
var watcom : String;
var eu_auto_exec_bat : String;
// Delete what the installer created at runtime.
begin
  euCfgFName := ExpandConstant('{app}\bin\eu.cfg');
  euCfgContents_theoretical := generateEuCfgString();
  euCfgContents_tested := '';
  if not LoadStringFromFile( euCfgFName, euCfgContents_tested )
    or (euCfgContents_tested = euCfgContents_theoretical) then
          begin
            DelayDeleteFile( euCfgFName, 1 );
          end;
  if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'PATH', path) then
      begin
      	   // get rid of the {app}/bin paths whether they have a semicolon or not. 
      	   StringChangeEx(path, ExpandConstant('{app}\bin;'), '', True);
           StringChangeEx(path, ExpandConstant('{app}\bin'), '', True);
           RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'PATH', path);
      end;
  if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'INCLUDE', include) then
      begin
        StringChangeEx(include, ExpandConstant('{app}\watcom\h;{app}\watcom\h\nt'), '', True);
    	RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'INCLUDE', include);
      end;
  if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'WATCOM', watcom) then
      begin
        RegDeleteValue(HKEY_CURRENT_USER, 'Environment', 'WATCOM');
      end;
  if LoadStringFromFile('C:\AUTOEXEC.BAT', eu_auto_exec_bat) then
      begin
      	if (StringChangeEx(eu_auto_exec_bat, ExpandConstant('{app}\bin'),
      		'', True) <> 0) then
          SaveStringToFile('C:\AUTOEXEC.BAT', eu_auto_exec_bat, False);
      end;
  Result := True;
end;

function NextButtonClick(CurPageID: Integer) : Boolean;
begin
  if (CurPageID = wpSelectDir) and ( Pos(' ', ExpandConstant('{app}')) <> 0) then
    begin
    MsgBox('The install directory cannot contain spaces.  Change the program name to some other value.  This is a Watcom issue.', mbError, MB_OK);
    Result := False;
    end
  else
  Result := True;
end;
