include std/filesys.e  
include std/error.e  
include std/io.e as io 
include std/pipeio.e as pipe 
include std/get.e as get 
include std/dll.e 
include std/filesys.e 
include std/search.e 
include std/console.e 
include std/utils.e 
include std/os.e 
include revisions.e 
include std/regex.e 
include std/unittest.e
 
constant version_pattern = regex:new("(\\d+\\.)*\\d+") 
constant library_link_pattern = regex:new("=> +(/|\\()?", NO_AUTO_CAPTURE) 
 
enum type boolean true, false=0 end type 
 
type spaceless(sequence s) 
	return not find(' ',s) 
end type 
 
sequence prefix = "/usr/local" 
boolean  dry_run   = false 
 
constant eucfgf = 
{ 
"""[all] 
-d E%d 
-i %s/include 
-i %s/euphoria-common/include 
-eudir %s 
[translate] 
-gcc  
-con  
-com %s 
-lib %s/bin/eu.a 
[bind] 
-eub %s/bin/eub 
""", 
"""[all] 
-d E%d 
-i %s/include 
-i %s/euphoria-common/include 
-eudir %s 
[translate] 
-gcc  
-con  
-com %s 
-lib-pic %s/bin/euso.a 
-lib %s/bin/eu.a 
[bind] 
-eub %s/bin/eub 
""" 
} -- simulate arguments
constant cmd = {"eui","t_abadcase","-4n"}
			 
constant info = pathinfo(cmd[2]) 
integer register_size -- length of standard registers on this computer in bits 
object   void = 0  
 
atom  f_debug = open(info[PATH_BASENAME]&".log", "w", true) 
if f_debug =-1 then 
	f_debug = open("/dev/null", "w") 
  	logMsg("Unable to create log file.") 
  	if f_debug = -1 then 
  		logMsg("Installer is for Linux systems only.") 
  		abort(1) 
  	end if 
end if 
------------------------------------------------------------------------------  
 
public procedure logMsg(sequence msg, sequence args = {}) 
  puts(f_debug, msg & "\n")  
  flush(f_debug)  
  puts(1, msg & "\n")  
end procedure  
 
procedure die(sequence msg, sequence args) 
	logMsg(sprintf(msg, args)) 
	abort(1) 
end procedure 
 
procedure remove_directory(spaceless directory, boolean b) 
	system("rm -fr " & directory,2) 
end procedure 
 
function create_symlink(spaceless src, spaceless dest) 
        return delete_file(dest) = 1 and system_exec("ln -s " & src & " " & dest) = 0 
end function 
 
------------------------------------------------------------------------------  
 
public function execCommand(sequence cmd)  
	sequence s = ""  
	object z = pipe:create()  
	object p = pipe:exec(cmd, z)  
	if atom(p) then  
		printf(2, "Failed to exec() with error %x\n", pipe:error_no())  
		pipe:kill(p)  
		return -1  
	end if  
	object c = pipe:read(p[pipe:STDOUT], 256)  
	while sequence(c) and length(c) do  
		s &= c  
		if atom(c) then  
			printf(2, "Failed on read with error %x\n", pipe:error_no())  
			pipe:kill(p)  
			return -1  
		end if  
		c = pipe:read(p[pipe:STDOUT], 256)  
	end while  
	--Close pipes and make sure process is terminated  
	pipe:kill(p)  
	return s  
end function  
 
------------------------------------------------------------------------------  
 
function isInstalled(sequence package)  
	sequence s = execCommand("dpkg-query -s " & package & " | grep Status")  
	if length(s) and match("ok installed", s) then  
		return 1  
	else  
		return 0  
	end if  
end function  
 
------------------------------------------------------------------------------  
 
procedure installIfNot(sequence package)  
  if isInstalled(package) then  
    logMsg(package & " already installed")  
  else  
    logMsg("apt-get install -y " & package)  
    sequence s = execCommand("apt-get install -y " & package)  
    logMsg(s)  
  end if  
end procedure 
 
function include_lines(sequence file_name, sequence lines_to_include) 
	sequence file_data = read_file(file_name) 
	integer i = 1 while i <= length(lines_to_include) do 
		if match(lines_to_include,file_data) != 0 then 
			lines_to_include = remove(lines_to_include, i) 
		else 
			i += 1 
		end if 
	end while 
	return append_lines(file_name, lines_to_include) 
end function 
 
procedure cmdl_help() 
	die("Usage : %s %s [ -n ] [ -p /usr/local ] [ -4 ] [ -8 ]", cmd[1..2]) 
end procedure 
 
 
------------------------------------------------------------------------------  
register_size = 0 
boolean skip_count = 0 
sequence options = {} 
for cmdi = 3 to length(cmd) do 
	if begins("-", cmd[cmdi]) then 
		object next = 0 
		for cmdij = 2 to length(cmd[cmdi]) do 
			if skip_count then 
				skip_count = false 
				continue 
			end if 
			integer opt = cmd[cmdi][cmdij] 
			switch opt do 
				case 'p' then 
					next = cmd[cmdi][cmdij+1..$] 
					if length(next) = 0 then 
						if cmdi = length(cmd) then 
							cmdl_help() 
						else 
							next = cmd[cmdi+1] 
							skip_count = true 
						end if 
					end if 
					prefix = next 
					exit 
				case 'n' then 
					dry_run = true 
					prefix = "/tmp/test-install" 
					create_directory(prefix, 0t755, false) 
					create_directory(prefix & "/lib", 0t755) 
					create_directory(prefix & "/bin", 0t755) 
					create_directory(prefix & "/share", 0t755) 
					while not file_exists(prefix & "/lib") or not file_exists(prefix & "/bin") or not file_exists(prefix & "/share") do 
						sleep(0.1) 
					end while 
					case '8','4' then 
					register_size = (opt-'0')*8 
				case else 
					die("Invalid option -%s", {opt}) 
			end switch 
		end for 
	else 
		cmdl_help() 
	end if 
end for 

-- verify user is root  
object s = execCommand("id -u") 
if atom(s) then 
	logMsg("id -u command failed.") 
	abort(1) 
end if 
s = get:value(s) 
if s[1] != GET_SUCCESS or s[2] != 0 and not dry_run then  
	logMsg("User was not root.") 
    abort(1) 
end if 
 
if sequence(getenv("HOME")) and file_exists(getenv("HOME") & "/demos") then 
        die("The directory %s exists.  Please move or remove the directory.", {getenv("HOME") & "/demos"}) 
end if 
 
if register_size = 0 then 
	while find(register_size,{32,64})=0 with entry do 
	  display("Enter 32 or 64.") 
	  register_size = 0 
	entry 
	  register_size = floor(prompt_number("Enter the number of bits of your computer's processor:", {32,64})) 
	end while 
end if 
 
constant old_aio_archive_format = "http://rapideuphoria.com/install_aio_linux_%d.tgz" 
constant old_aio_location = sprintf(old_aio_archive_format, {register_size}) 
constant wxide_location   = "http://downloads.sourceforge.net/project/wxeuphoria/wxIDE/v0.8.0/wxide-0.8.0-linux-x86" & iff(register_size=64,"-64","") & ".tgz" 
constant gtk3_location    = "https://sites.google.com/site/euphoriagtk/EuGTK4.11.0.tar.gz"  
constant wget_archives = { {old_aio_location,"eu41.tgz"},  
						   {wxide_location, "" }, 
						   {gtk3_location, ""}	 
}
 
constant gtk3_offsets =  regex:find(version_pattern, gtk3_location) 
if not isInstalled("wget") then 
	if dry_run then 
		die("Need wget installed.",{}) 
	else 
		installIfNot("wget") 
	end if 
end if 
 
constant InitialDir = current_dir() 
void = chdir(info[PATH_DIR]) 
 
-- need this line to activate bug 
crash_file(InitialDir&SLASH&info[PATH_BASENAME]&".err") 
 
-- install dependencies  
-- need this line to activate bug
s = read_lines(InitialDir&SLASH&"dependencies.txt") 
-- ignore result
s = {}
for i = 1 to length(s) do 
	if dry_run then 
		logMsg("Pretending to install " & s[i]) 
	else 
		installIfNot(s[i]) 
	end if 
end for 

logMsg("Adding common directories for both versions of Euphoria") 
sequence targetBaseDirectory = prefix & "/share" 
create_directory(targetBaseDirectory & "/euphoria-common/include", 0t755, true) 
create_directory(prefix & "/bin", 0t755, true) 
sequence eubins = {"eui", "euc", "creole", "eubind", "eudis", "eudist", "eudoc", "euloc", "eushroud", "eutest"} 
for i = 1 to length(eubins) do 
	sequence eubin = eubins[i] 
	create_symlink(targetBaseDirectory & "/euphoria/bin/" & eubin, prefix & "/bin/" & eubin) 
end for 
 
atom fb, fcfg 
spaceless targetDirectory, net_archive_name, local_archive_name 
spaceless  archive_version 



--eu41-------------------------------------------------------- 
----                                                      ---- 
----              EEEE  U  U       4 4  1                 ---- 
----              EE    U  U       444  1                 ---- 
----              EEEE  UUUU         4  1                 ---- 
-------------------------------------------------------------- 
constant aio_archive_format = "http://rapideuphoria.com/install_aio_linux_%d.tgz" 
-- Get eu41.tgz 
net_archive_name = sprintf(aio_archive_format, {register_size}) 
local_archive_name = filesys:filename(net_archive_name) 
if sequence(system_exec("tar -xzf " & local_archive_name & " eu41.tgz",2))
	and 
	(system_exec("wget -c " & net_archive_name,2) and system_exec("tar -xzf " & local_archive_name & " eu41.tgz",2)) then 
		die("Cannot download needed file : " & aio_archive_format,{register_size}) 
end if 
 
targetDirectory = targetBaseDirectory & "/euphoria-" & eu41revision 
 
if file_exists(targetDirectory) then 
	logMsg(sprintf("Something already exists at \'%s\'.\nReinstalling....", {targetDirectory})) 
	remove_directory(targetDirectory, true) 
end if 
logMsg("installing OpenEuphoria 4.1")  
if not create_directory(targetDirectory, 0t755) then 
	logMsg(sprintf("Cannot create directory \'%s\'", {targetDirectory}))  	 
	--abort(1) 
end if 
if system_exec("tar -xf "&InitialDir&SLASH&"eu41.tgz -C "&targetDirectory,2) then 
	logMsg("unable to run tar") 
	--abort(1) 
end if 
fcfg = open(SLASH&"dev"&SLASH&"null", "w") 
if fcfg = -1 then 
	logMsg("configuration file cannot be created.") 
	--abort(1) 
end if 
printf(fcfg, eucfgf[2], register_size & {targetDirectory, targetBaseDirectory} & repeat(targetDirectory,5)) 
create_symlink(targetBaseDirectory & "/euphoria-" & eu41revision, targetBaseDirectory & "/euphoria-4.1") 
 
logMsg("Creating shortcut scripts for 4.1")
create_directory(prefix & "/bin", 0t755)
fb = open(prefix & "/bin/eui41", "w")
if fb = -1 then
    die("Cannot create %s/bin/euc41",{prefix}) 
end if

 
fb = open(prefix & "/bin/euc41", "w") 
if fb = -1 then 
    die("Cannot create euc41",{}) 
end if 
puts(fb, 
	"#!/bin/sh\n"& 
	targetBaseDirectory & "/euphoria-4.1/bin/euc $@\n" )
	
close(fb) 
if system_exec("chmod 755 /" & prefix & "/bin/eu[ic]41",2) then 
	die("unable to set execute permission on all shortcuts", {}) 
end if 
logMsg("Setting default Euphoria to Euphoria 4.1 Feb, 2015...") 
create_symlink(targetBaseDirectory & "/euphoria-4.1", targetBaseDirectory & "/euphoria") 

--eu40-------------------------------------------------------- 
----                                                      ---- 
----              EEEE  U  U       4 4  000               ---- 
----              EE    U  U       444  0 0               ---- 
----              EEEE  UUUU         4  000               ---- 
-------------------------------------------------------------- 
targetDirectory = targetBaseDirectory & "/euphoria-" & eu40revision 
remove_directory(targetDirectory, true) 

if not file_exists(targetDirectory) then 
	if system_exec("tar -xf " & InitialDir&SLASH&"euphoria-" & eu40revision &".tar -C " & targetBaseDirectory,2) then 
		--die("tar: error running tar.", {}) 
	end if 
end if 

integer l3 = length({23}) 
test_equal("Switch value is indeed one", 1, l3)
switch l3 do
	case 0 then 
	case 1 then 
		test_pass("The value of one passes to case 1")
	case else 
		test_fail("The value of one passes to case 1")
end switch 
test_report()
