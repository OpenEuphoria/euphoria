
ifdef EUI then

include std/cmdline.e
include std/filesys.e
include std/get.e
include std/io.e


sequence cmd = command_line()

ifdef LOCK_TEST then
	sequence file
	object locktype

	{ ?, ?, file, locktype } = cmd
	{?, locktype} = value( locktype )
	
	integer fn, success
	fn = open( file, "r" )
	if fn != -1 then
			success = lock_file( fn, locktype )
		close(fn)
	else
		success = -1
	end if
	abort( success )

elsedef

	include std/unittest.e
	-- main test
	sequence eui, t_lockfile
	{ eui, t_lockfile } = cmd
	test_equal( "LOCK_EXCLUSIVE LOCK_EXCLUSIVE",   0, run( eui, t_lockfile, LOCK_EXCLUSIVE ) )
	test_equal( "LOCK_EXCLUSIVE LOCK_SHARED", 0, run( eui, t_lockfile, LOCK_EXCLUSIVE ) )
	test_equal( "LOCK_SHARED LOCK_SHARED",      1, run( eui, t_lockfile, LOCK_SHARED ) )
	test_equal( "LOCK_SHARED LOCK_EXCLUSIVE",    0, run( eui, t_lockfile, LOCK_SHARED, LOCK_EXCLUSIVE ) )

	function run( sequence eui, sequence t_lockfile, integer locktype, integer test_locktype = locktype )
		sequence file = temp_file()
		integer fn = open( file, "w" )
		close(fn)
		fn = open( file, "r" )
		integer test = lock_file( fn, locktype )
		sequence lockname
		if locktype = LOCK_SHARED then
			lockname = "LOCK_SHARED"
		elsif locktype = LOCK_EXCLUSIVE then
			lockname = "LOCK_EXCLUSIVE"
		else
			lockname = "unknown lock type"
		end if
		test_true( sprintf("locked file with %s", {lockname}), test )
		if test then
			test = system_exec( build_commandline({
					eui,
					"-d=LOCK_TEST",
					t_lockfile,
					file,
					sprintf("%d", test_locktype )
				}), 2 )
		end if
		close(fn)
		delete_file( file )
		return test
	end function
	test_report()
end ifdef
end ifdef
