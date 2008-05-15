-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--

include common.e
include misc.e
include machine.e
include file.e

atom oem2char,convert_buffer
integer convert_length
global atom u32,fc_table,char_upper
constant C_POINTER = #02000004
sequence regs
if platform()=WIN32 then
	u32=machine_func(50,"user32.dll")
	oem2char=machine_func(51,{u32,"OemToCharA",{C_POINTER,C_POINTER},C_POINTER})
	char_upper=machine_func(51,{u32,"CharUpperA",{C_POINTER},C_POINTER})
	convert_length=64
	convert_buffer=allocate(convert_length)
elsif platform()=DOS32 then
	regs=repeat(0,10)
	fc_table=allocate_low(5)
	-- query filename country dependent capitalisation table pointer
	regs[REG_DX]=and_bits(fc_table,15)
	regs[REG_DS]=floor(fc_table/16)
	regs[REG_AX]=#6504
	regs=dos_interrupt(#21,regs)
	if and_bits(regs[REG_FLAGS],1) then -- DOS earlier than 4.0, or something very wrong
		free_low(fc_table)
		fc_table=0
	else -- turn received dword into a 32 bit address, altered so as to access it faster
		regs=peek({fc_table+1,4})
		free_low(fc_table)
		fc_table=regs[1]+256*regs[2]+16*regs[3]+4096*regs[4]-126
	end if
end if

function convert_from_OEM(sequence s)
	integer ls,rc
	
	ls=length(s)
	if ls>convert_length then
		free(convert_buffer)
		convert_length=and_bits(ls+15,-16)+1
		convert_buffer=allocate(convert_length)
	end if
	poke(convert_buffer,s)
	poke(convert_buffer+ls,0)
	rc=c_func(oem2char,{convert_buffer,convert_buffer}) -- always nonzero
	return peek({convert_buffer,ls}) 
end function

constant include_subfolder = SLASH & "include"

sequence cache_vars
cache_vars = {}
sequence cache_strings
cache_strings = {}
sequence cache_substrings
cache_substrings = {}
sequence cache_starts
cache_starts = {}
sequence cache_ends
cache_ends  = {}
sequence cache_converted
if platform()=WIN32 then
	cache_converted = {}
end if
sequence cache_complete
cache_complete = {}
sequence cache_delims
cache_delims = {}
integer num_var

sequence config_inc_paths
config_inc_paths = {}
integer loaded_config_inc_paths
loaded_config_inc_paths = 0

object exe_path_cache
exe_path_cache = 0

sequence pwd
pwd = current_dir()

global function exe_path()
	
	if sequence(exe_path_cache) then
		return exe_path_cache
	end if

	exe_path_cache = command_line()
	exe_path_cache = exe_path_cache[1]
	
	return exe_path_cache
end function

function check_cache(sequence env,sequence inc_path)
	integer delim,pos

	if not num_var then -- first time the vr is accessed, add cache entry
		cache_vars = append(cache_vars,env)
		cache_strings = append(cache_strings,inc_path)
		cache_substrings = append(cache_substrings,{})
		cache_starts = append(cache_starts,{})
		cache_ends = append(cache_ends,{})
		if platform()=WIN32 then
			cache_converted = append(cache_converted,{})
		end if
		num_var = length(cache_vars)
		cache_complete &= 0
		cache_delims &= 0
		return 0
	else
		if compare(inc_path,cache_strings[num_var]) then
			cache_strings[num_var] = inc_path
			cache_complete[num_var] = 0
			if match(cache_strings[num_var],inc_path)!=1 then -- try to salvage what we can
				pos = -1
				for i=1 to length(cache_strings[num_var]) do
					if cache_ends[num_var][i] > length(inc_path) or 
					  compare(cache_substrings[num_var][i],inc_path[cache_starts[num_var][i]..cache_ends[num_var][i]]) then
						pos = i-1
						exit
					end if
					if pos = 0 then
						return 0
					elsif pos >0 then -- crop cache data
						cache_substrings[num_var] = cache_substrings[num_var][1..pos]
						cache_starts[num_var] = cache_starts[num_var][1..pos]
						cache_ends[num_var] = cache_ends[num_var][1..pos]
						if platform()=WIN32 then
							cache_converted[num_var] = cache_converted[num_var][1..pos]
						end if
						delim = cache_ends[num_var][$]+1
						while delim <= length(inc_path) and delim != PATH_SEPARATOR do
							delim+=1
						end while
						cache_delims[num_var] = delim
					end if
				end for
			end if
		end if
	end if
	return 1
end function


global function get_conf_dirs()
	integer delimiter
	sequence dirs
	
	if ELINUX then
		delimiter = ':'
	else
		delimiter = ';'
	end if
	
	dirs = ""
	for i = 1 to length(config_inc_paths) do
		dirs &= config_inc_paths[i]
		if i != length(config_inc_paths) then
			dirs &= delimiter
		end if
	end for
	return dirs
end function

function strip_file_from_path( sequence full_path )
	for i = length(full_path) to 1 by -1 do
		if full_path[i] = SLASH then
			return full_path[1..i]
		end if
	end for
	return ""
end function

function expand_path( sequence path, sequence prefix )
	object home
	integer absolute
	
	if not length(path) then
		return pwd
	end if
	
	if ELINUX and length(path) and path[1] = '~' then
		home = getenv("HOME")
		if sequence(home) and length(home) then
			path = home & path[2..$]
		end if
	end if
	
	absolute = find(path[1], SLASH_CHARS) or
		(not ELINUX and find(':', path))
	if not absolute then
		path = prefix & SLASH & path
	end if
	
	if length(path) and not find(path[$], SLASH_CHARS) then
		path &= SLASH
	end if
	
	return path
end function

global procedure add_include_directory( sequence path )

	path = expand_path( path, pwd )
   
	if not find( path, config_inc_paths ) then
		config_inc_paths = append( config_inc_paths, path )
	end if
end procedure

global procedure load_euinc_conf( sequence file )
	integer fn, absolute
	object in, home
	sequence conf_path
	
	conf_path = strip_file_from_path( file )
	home = ""
	
	if length(conf_path) = 0 then
		conf_path = pwd
	else
		conf_path = expand_path( conf_path, pwd )
	end if
	
	fn = open( file, "r" )
	if fn = -1 then return end if
	
	in = gets( fn )
	while sequence( in ) do
		while length(in) and find( in[$], "\n\r \t" ) do
			in = in[1..$-1]
		end while
		
		while length(in) and find( in[1], " \t" ) do
			in = in[2..$]
		end while
		
		if length(in) and match( "--", in ) != 1 then
			in = expand_path( in, conf_path )  -- allow ~ to refer to $HOME in *nix
			absolute = find(in[1], SLASH_CHARS) or
			   (not ELINUX and find(':', in))
			

			config_inc_paths = append( config_inc_paths, in )
		end if
		
		in = gets( fn )
	end while
	close(fn)
end procedure



global procedure load_platform_inc_paths()
	object env
	
	if loaded_config_inc_paths then return end if
	loaded_config_inc_paths = 1

	-- load the local (same dir as interpreter/translator)
	env = strip_file_from_path( exe_path() )
	load_euinc_conf( env & "euinc.conf" )
	
	-- platform specific
	if ELINUX then
		env = getenv( "HOME" )
		if sequence(env) then
			load_euinc_conf( env & "/.euinc.conf" )
		end if
		load_euinc_conf( "/etc/euphoria/euinc.conf" )
		
	elsif EWINDOWS then
		env = getenv( "APPDATA" )
		if sequence(env) then
			load_euinc_conf( expand_path( "euphoria", env ) & "euinc.conf" )
		end if

		env = getenv( "ALLUSERSPROFILE" )
		if sequence(env) then
			load_euinc_conf( expand_path( "euphoria", env ) & "euinc.conf" )
		end if
	else
		-- none for DOS
	end if
end procedure

global function ConfPath(sequence file_name)
-- Search directories listed on command line and in conf files
	sequence full_path, file_path
	integer try
	if not loaded_config_inc_paths then
		load_platform_inc_paths()
	end if
	for i = 1 to length(config_inc_paths) do
		full_path = config_inc_paths[i]
		file_path = full_path & file_name
		try = open( file_path, "r" )
		if try != -1 then
			return {file_path, try}
		end if
	end for
	return -1
end function

global function ScanPath(sequence file_name,sequence env,integer flag)
-- returns -1 if no path in geenv(env) leads to file_name, else {full_path,handle}
-- if flag is 1, the include_subfolder constant is prepended to filename
	object inc_path
	sequence full_path, file_path, strings
	integer end_path,start_path,try,use_cache, pos

-- 
-- Search directories listed on EUINC environment var
	inc_path = getenv(env)
	if compare(inc_path,{})!=1 then -- nothing to do, just fail
		return -1
	end if

	num_var = find(env,cache_vars)
	use_cache = check_cache(env,inc_path)
	inc_path = append(inc_path, PATH_SEPARATOR)

	file_name = SLASH & file_name
	if flag then
		file_name = include_subfolder & file_name
	end if
	strings = cache_substrings[num_var]

	if use_cache then
		for i=1 to length(strings) do
			full_path = strings[i]
			file_path = full_path & file_name
			try = open(file_path, "r")    
			if try != -1 then
				return {file_path,try}
			elsif platform()=WIN32 and sequence(cache_converted[num_var][i]) then
				-- perhaps this path entry, which had never been checked valid, is so after conversion
				full_path = cache_converted[num_var][i]
				file_path = full_path & file_name
				try = open(file_path, "r")
				if try != -1 then
					cache_converted[num_var][i] = 0
					cache_substrings[num_var][i] = full_path
					return {file_path,try}
				end if
			end if
		end for
		if cache_complete[num_var] then -- nothing to scan
			return -1
		else
			pos = cache_delims[num_var]+1 -- scan remainder, starting from as far sa possible
		end if
	else -- scan from scratch
		pos = 1
	end if

	start_path = 0
	for p = pos to length(inc_path) do
		if inc_path[p] = PATH_SEPARATOR then
					-- end of a directory.
			cache_delims[num_var] = p
					-- remove any trailing blanks and SLASH in directory
			end_path = p-1
			while end_path >= start_path and find(inc_path[end_path], " \t" & SLASH_CHARS) do
				end_path-=1
			end while

			if start_path and end_path then
				full_path = inc_path[start_path..end_path]
				cache_substrings[num_var] = append(cache_substrings[num_var],full_path)
				cache_starts[num_var] &= start_path
				cache_ends[num_var] &= end_path
				file_path = full_path & file_name  
				try = open(file_path, "r")
				if try != -1 then -- valid path, no point trying to convert
					if platform()=WIN32 then  
						cache_converted[num_var] &= 0
					end if
					return {file_path,try}
				elsif platform()=WIN32 then  
					if find(1,full_path>=128) then
  -- accented characters, try converting them
						full_path = convert_from_OEM(full_path)
						file_path = full_path & file_name
						try = open(file_path, "r")
						if try != -1 then -- that was it; record translation as the valid path
							cache_converted[num_var] &= 0
							cache_substrings[num_var] = append(cache_substrings[num_var],full_path)
							return {file_path,try}
						else -- we know we know nothing so far about this path entry
							cache_converted[num_var] = append(cache_converted[num_var],full_path)
						end if
					else -- nothing to convert anyway
						cache_converted[num_var] &= 0
					end if
				end if
				start_path = 0
			end if
		elsif not start_path and (inc_path[p] != ' ' and inc_path[p] != '\t') then
			start_path = p
		end if
	end for
	-- everything failed: mark variable as completely read, so as not to scan again if unmodified
	cache_complete[num_var] = 1
	return -1
end function

-- open a file by searching the user's PATH

global function e_path_open(sequence name, sequence mode)
-- follow the search path, if necessary to open the main file
	integer src_file
	object scan_result

	-- try opening directly
	src_file = open(name, mode)
	if src_file != -1 then
		return src_file        
	end if
	
	-- make sure that name is a simple name without '\' in it
	for i = 1 to length(SLASH_CHARS) do
		if find(SLASH_CHARS[i], name) then
			return -1
		end if
	end for
	
	scan_result = ScanPath(name,"PATH",0)
	if atom(scan_result) then
		return -1
	else
		file_name[1] = scan_result[1]
		return scan_result[2]
	end if
	
end function


