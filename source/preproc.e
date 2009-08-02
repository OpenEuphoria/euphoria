include std/filesys.e
include std/sequence.e
include std/datetime.e as dt
include std/dll.e

include common.e
include error.e

enum PP_EXTENSION, PP_COMMAND, PP_RID

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
--   # ##file_extension##: file extension of this pre-processor
--	 # ##command##: pre-processor command name
--	 

public procedure add_preprocessor(sequence file_ext, sequence command)
	sequence exts = split(file_ext, ",")
	for i = 1 to length(exts) do
		preprocessors &= { { exts[i], command, -1 } }
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
		
	sequence post_fname = filebase(fname) & "_post." & fileext(fname)
	if length(dirname(fname)) > 0 then
		post_fname = dirname(fname) & SLASH & post_fname
	end if

	if not is_file_newer(fname, post_fname) then
		return post_fname
	end if
	
	sequence cmd = pp[PP_COMMAND]

	if equal(fileext(cmd), SHARED_LIB_EXT) then
		integer rid = pp[PP_RID]
		if rid = -1 then
			integer dll_id = open_dll(cmd)
			if dll_id = -1 then
				CompileErr(sprintf("Preprocessor shared library '%s' could not be loaded\n",
					{ pp[PP_COMMAND] }))
			end if

			rid = define_c_func(dll_id, "preprocess", { E_SEQUENCE, E_SEQUENCE }, E_INTEGER)
			if rid = -1 then
				CompileErr("Preprocessor entry point cound not be found\n")
			end if

			preprocessors[pp_id][PP_RID] = rid
		end if
		
		if c_func(rid, { fname, post_fname }) = 0 then
			CompileErr("Preprocessor call failed\n")
		end if
	else
		if equal(fileext(cmd), "ex") then
			cmd = "eui " & cmd
			cmd &= sprintf(" %s %s", { fname, post_fname })
			
			if system_exec(cmd, 2) then
				CompileErr(sprintf("Preprocessor command failed: %s\n", { cmd }))
			end if
		end if
	end if
	
	return post_fname
end function
