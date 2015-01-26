; When making changes to this file, remember to make a similar change to
; euphoria-ow.iss

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
DefaultDirName=c:\Euphoria
DefaultGroupName=Euphoria
AllowNoIcons=yes
LicenseFile=..\..\license.txt
DisableStartupPrompt=yes
DisableReadyPage=yes
OutputDir=.\
OutputBaseFilename=euphoria-4.0.6
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
ChangesEnvironment=yes
InfoBeforeFile=before.txt
InfoAfterFile=after.txt
; set the minimum environment required to 
; Windows NT or higher (Inno Setup has discontinued support for Windows 9x!) (see ticket 665)
MinVersion=5.0

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

; Files to Install
; Root
Source: "cleanbranch\file_id.diz"; DestDir: {app}; Flags: ignoreversion;
Source: "cleanbranch\license.txt"; DestDir: {app}; Flags: ignoreversion;

; Windows Binaries
Source: "..\..\source\build\eu.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eu.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eub.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eubind.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eubw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\euc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eudbg.a"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eudbg.lib"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eui.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main; AfterInstall: InstallEuCfg
Source: "..\..\source\build\euiw.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "..\..\source\build\eushroud.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\source\eufile.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main
Source: "cleanbranch\source\euphoria.ico"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_main

; Windows Tools
Source: "..\..\source\build\creole.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\eucoverage.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\eudis.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\eudist.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\eudoc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\euloc.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "..\..\source\build\eutest.exe"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Generic Tools
Source: "cleanbranch\bin\*.bat"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.ex"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools
Source: "cleanbranch\bin\*.exw"; DestDir: {app}\bin\; Flags: ignoreversion; Components: comp_tools

; Demos
Source: "cleanbranch\demo\*.*"; DestDir: {app}\demo\; Flags: ignoreversion recursesubdirs; Components: comp_demos

; Docs
Source: "..\..\source\build\euphoria.pdf"; DestDir: {app}\docs\; Flags: ignoreversion; Components: comp_docs
Source: "..\..\source\build\html\*.*"; DestDir: {app}\docs\html\; Flags: ignoreversion recursesubdirs; Components: comp_docs

; Includes
Source: "cleanbranch\include\*.*"; DestDir: {app}\include\; Flags: ignoreversion recursesubdirs; Components: comp_main

; Sources
Source: "cleanbranch\source\*.*"; DestDir: {app}\source\; Flags: ignoreversion; Components: comp_source
Source: "cleanbranch\source\codepage\*.*"; DestDir: {app}\source\codepage; Flags: ignoreversion; Components: comp_source
Source: "cleanbranch\source\pcre\*.*"; DestDir: {app}\source\pcre; Flags: ignoreversion; Components: comp_source

; Test
Source: "cleanbranch\tests\*.*"; DestDir: {app}\tests\; Flags: ignoreversion recursesubdirs; Components: comp_tests

; Tutorial
Source: "cleanbranch\tutorial\*.*"; DestDir: {app}\tutorial\; Flags: ignoreversion recursesubdirs; Components: comp_tuts


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

;associate .exw files to be called by euiw.exe
Root: HKCR; Subkey: ".exw"; ValueType: string; ValueName: ""; ValueData: "EUWinApp"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Windows App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\source\build\eufile.ico"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\source\build\euiw.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUWinApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\source\build\euc.exe"" ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;associate .ex files to be called by eui.exe
Root: HKCR; Subkey: ".ex"; ValueType: string; ValueName: ""; ValueData: "EUConsoleApp"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp"; ValueType: string; ValueName: ""; ValueData: "Euphoria Console App"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\source\build\eufile.ico"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\source\build\eui.exe"" ""%1"" %*"; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUConsoleApp\shell\translate\command"; ValueType: string; ValueName: ""; ValueData: """{app}\source\build\euc.exe"" -con ""%1"""; Flags: uninsdeletekey createvalueifdoesntexist; Tasks: associate

;create an icon link for .e files
Root: HKCR; Subkey: ".e"; ValueType: string; ValueName: ""; ValueData: "EUInc"; Flags: deletekey uninsdeletevalue createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUInc"; ValueType: string; ValueName: ""; ValueData: "Euphoria Include File"; Flags: deletekey uninsdeletekey createvalueifdoesntexist; Tasks: associate
Root: HKCR; Subkey: "EUInc\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\source\build\eufile.ico"; Flags: deletekey uninsdeletekey createvalueifdoesntexist; Tasks: associate

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
  euCfgFName := ExpandConstant('{app}\source\build\eu.cfg');
   incLine := ExpandConstant('-i {app}\include');
  Result := #13#10 + '[all]' + #13#10 + incLine + #13#10;
end;

procedure InstallEuCfg();
var
  euCfgFname : String;
  incLine : String;

begin
  incLine := ExpandConstant('-i {app}\include');
  euCfgFname := ExpandConstant('{app}\source\build\eu.cfg');

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
var eu_auto_exec_bat : String;
// Undo what the installer changed at runtime.
begin
  euCfgFName := ExpandConstant('{app}\source\build\eu.cfg');
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
 Result := True;
end;
