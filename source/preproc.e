-- (c) Copyright - See License.txt

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/filesys.e
include std/sequence.e
include std/datetime.e as dt
include std/dll.e
include std/cmdline.e as cmdline

include global.e
include common.e
include error.e

enum PP_EXTENSION, PP_COMMAND, PP_PARAMS, PP_RID

function is_file_newer(sequence f1, sequence f2)
	object d1 = file_timestamp(f1)
	object d2 = file_timestamp(f2)
	
	if atom(d2) then return 1 end if

	if dt:diff(d1, d2) < 0 then
		return 1
	end if

	return 0
end function

--**
-- Add a pre-processor
-- 
-- Parameters:
--   # ##file_ext##: file extension of this pre-processor -or- if command
--	   is zero, file_ext is the pre-processor definition string, i.e.
--	   de,dex:dot4.ex
--	 # ##command##: pre-processor command name
--	 # ##params##: parameters to send to the pre-processor
--	 

public procedure add_preprocessor(sequence file_ext, object command=0, object params=0)
	if atom(command) then
		sequence tmp = split( file_ext, ":")
		file_ext = tmp[1]
		command = tmp[2]
		if length(tmp) >= 3 then
			params = tmp[3]
		end if
	end if

	sequence file_exts = split( file_ext, "," )
	
	if atom(params) then
		params = ""
	end if
	
	sequence exts = split(file_ext, ",")
	for i = 1 to length(exts) do
		preprocessors &= { { exts[i], command, params, -1 } }
	end for
end procedure 

--**
-- Pre-process a file based on it's extension and return the new filename.
-- 
-- If no preprocessors exist for the extension or if no preprocessors were
-- defined, then the original filename is returned.
-- 
-- Parameters:
--   # ##fname##: Filename to preprocess
--	 
-- Returns:
--   Post-processed filename
--

public function maybe_preprocess(sequence fname)
	sequence pp = {}
	integer pp_id

	if length(preprocessors) then
		sequence fext = fileext(fname)

		for i = 1 to length(preprocessors) do
			if equal(fext, preprocessors[i][1]) then
				pp_id = i
				pp = preprocessors[pp_id]
				exit
			end if
		end for
	end if
		
	if length(pp) = 0 then 
		return fname
	end if
		
	sequence post_fname = filebase(fname) & ".pp." & fileext(fname)
	if length(dirname(fname)) > 0 then
		post_fname = dirname(fname) & SLASH & post_fname
	end if

	if not force_preprocessor then
		if not is_file_newer(fname, post_fname) then
			return post_fname
		end if
	end if
	

	if equal(fileext(pp[PP_COMMAND]), SHARED_LIB_EXT) then
		integer rid = pp[PP_RID]
		if rid = -1 then
			integer dll_id = open_dll(pp[PP_COMMAND])
			if dll_id = -1 then
				CompileErr(sprintf("Preprocessor shared library '%s' could not be loaded\n",
					{ pp[PP_COMMAND] }),,1)
			end if

			rid = define_c_func(dll_id, "preprocess", { E_SEQUENCE, E_SEQUENCE, E_SEQUENCE }, 
				E_INTEGER)
			if rid = -1 then
				CompileErr("Preprocessor entry point cound not be found\n",,1)

				Cleanup(1)
			end if

			preprocessors[pp_id][PP_RID] = rid
		end if
		
		if c_func(rid, { fname, post_fname, pp[PP_PARAMS] }) != 0 then
			CompileErr("Preprocessor call failed\n",,1)

			Cleanup(1)
		end if
	else
		sequence public_cmd_args = {pp[PP_COMMAND]}
		sequence cmd_args = {canonical_path(pp[PP_COMMAND],,TO_SHORT)}
		
		if equal(fileext(pp[PP_COMMAND]), "ex") then
			public_cmd_args = { "eui" } & public_cmd_args
			cmd_args = { "eui" } & cmd_args
		end if

		cmd_args &= { "-i", canonical_path(fname,,TO_SHORT), "-o", canonical_path(post_fname,,TO_SHORT) }
		public_cmd_args &= { "-i", fname, "-o", post_fname }
		sequence cmd = build_commandline( cmd_args ) & pp[PP_PARAMS]
		sequence pcmd = build_commandline(public_cmd_args) & pp[PP_PARAMS]
		integer result = system_exec(cmd, 2)
		if result != 0 then
			CompileErr(sprintf("Preprocessor command failed (%d): %s\n", { result, pcmd } ),,1)

			Cleanup(1)
		end if
	end if
	
	return post_fname
end function
