include std/filesys.e 
include std/unittest.e
include std/os.e
ifdef LINUX then
	include std/dll.e
	constant libc = open_dll("libc")
	constant c_alarm = define_c_func(libc, "alarm", {C_UINT}, C_UINT)
end ifdef
sequence names = {}
function my_function( sequence path_name, sequence item )
	names = append(names, item[D_NAME])
	return 0
end function 

-- WINDOWS doesn't allow * in filenames.
ifdef not WINDOWS then
	create_directory("tmp")
	create_directory("tmp/*.*")
	create_directory("tmp/sue")
	-- wait for the fs changes to become visible here
	while file_exists("tmp/*.*") = 0 do
		sleep(0.001)
	end while
	ifdef LINUX then
		-- On Linux, thanks to this alarm call,
		-- if the next calls take more than ten seconds,
		-- an alarm will go off and kill this process.
		-- eutest will be able to continue its testing.
		c_func(c_alarm, {10})
	end ifdef
	walk_dir( "tmp", routine_id( "my_function" ), 1 )
	test_pass( "walkdir works with a *.* directory" )
	ifdef LINUX then
		c_func(c_alarm, {0})
	end ifdef
end ifdef
test_report()
