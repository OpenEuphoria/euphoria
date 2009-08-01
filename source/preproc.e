include std/filesys.e
include std/sequence.e
include std/datetime.e as dt

include common.e
include error.e

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

export function maybe_preprocess(sequence fname)
	sequence pp = {}

	if length(preprocessors) then
		sequence fext = fileext(fname)

		for i = 1 to length(preprocessors) do
			if equal(fext, preprocessors[i][1]) then
				pp = preprocessors[i]
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
	
	sequence cmd = pp[2]
	
	if equal(fileext(cmd), "ex") then
		cmd = "eui " & cmd
	end if
	
	cmd &= sprintf(" %s %s", { fname, post_fname })

	integer pp_status = system_exec(cmd, 2)
	if pp_status != 0 then
		CompileErr(sprintf("Preprocessor command failed: %s\n", { cmd }))
	end if

	return post_fname
end function
