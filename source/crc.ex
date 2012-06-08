-- (c) Copyright - See License.txt
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
include std/io.e

constant src_files = {
-- front end
"eui.ex",
"euc.ex",
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
"msgtext.e",
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

integer global_sum, local_sum, c
global_sum = 0
object fn

for i = 1 to length(src_files) do
	fn = read_file(src_files[i], TEXT_MODE)
	if equal(fn, -1) then
		printf(2, "can't open '%s'\n", {src_files[i]})
		abort(1)
	end if
	
	local_sum = 0
	for j = 1 to length(fn) do
		c = fn[j]
		local_sum = remainder(local_sum + c * j, 1_000_000_003)
	end for
	
	global_sum = remainder(global_sum + local_sum, 1_000_000_003)
	printf(1, "%-20s: %08x\n", {src_files[i], local_sum})
end for

printf(1, "\n%d files. Total: %x\n", {length(src_files), global_sum})

