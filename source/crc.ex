-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Compute a checksum on the source files.
-- This is useful when you are porting to a new machine.
-- It lets you verify that the source files are the same on the 
-- two machines, in case you are wondering if you made any changes.
--
-- The displayed checksum numbers accumulate from one file to the next,
-- so you can easily see where things start to differ. All numbers
-- reported after that will be wrong.
--
-- Differences in line terminators (\r \n) do not affect the numbers.

constant src_files = {
-- front end
"int.ex",
"ec.ex",
"eu.ex",
"main.e",
"pathopen.e",
"error.e",
"symtab.e",
"scanner.e",
"emit.e",
"parser.e",
"backend.e",
"compress.e",
"il.e",
"backend.ex", -- might be different on FreeBSD
--"global.e",   -- might be different on FreeBSD
"keylist.e",
"reswords.e",
"compile.e",
"c_out.e",
"c_decl.e",
"opnames.e",
"traninit.e",
-- back end
"be_main.c",
"be_symtab.c",
"be_callc.c",  -- might be different on ListFilter/Linux
"be_alloc.c",
"be_machine.c",
"be_rterror.c",
"be_syncolor.c",
"be_w.c",
"be_inline.c",
"be_runtime.c",
"be_execute.c",
"be_task.c",
-- .h files
"alloc.h",
"execute.h",
"global.h",
"opnames.h",
"redef.h",
"reswords.h",
"symtab.h",
"alldefs.h",
"crc.ex"
}

integer global_sum, local_sum, c, count
global_sum = 0
integer fn

for i = 1 to length(src_files) do
	fn = open(src_files[i], "r")
	if fn = -1 then
		printf(2, "can't open '%s'\n", {src_files[i]})
		abort(1)
	end if
	local_sum = 0
	count = 1
	while 1 do
		c = getc(fn)
		if c = -1 then
			exit
		end if
		if c != '\n' and c != '\r' then
			local_sum = remainder(local_sum + c * count, 100000000)
			count += 1
		end if
	end while
	close(fn)
	
	global_sum = remainder(global_sum + local_sum, 100000000)
	printf(1, "%s: %x\n", {src_files[i], global_sum})
end for

printf(1, "\n%d files. Total: %x\n", {length(src_files), global_sum})

