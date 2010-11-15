-- (c) Copyright - See License.txt
--
--****
-- == Windows Extended Filesystem Functionality
--
-- <<LEVELTOC level=2 depth=4>>
--

include std/dll.e
include std/filesys.e
include std/machine.e

constant lib = open_dll("kernel32")
constant xGetVolumeInfo    = define_c_func( lib, "GetVolumeInformationA", {C_POINTER, C_POINTER, C_UINT, C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_UINT }, C_INT)

--**
-- Returns volume information (the serial number) for the provided drive
--
-- Parameters:
--	# ##root_dir## : An object. This is the drive specification for which you want the information.
--					 Default is the C:\ drive (typically the first hard drive on Wintel PCs).
--
-- Returns:
--     An **atom**, the volume serial number or -1 if it could not be ascertained.
--                  
-- Examples:
-- <eucode>
-- res = getVolSerial( "C:\\" )
-- res = getVolSerial( "\\\\NETWORK_DRIVE\\PATH\\" )
-- res = getVolSerial( 'D' )
-- </eucode>

public function get_vol_serial( object root_dir = "C:\\" )
atom ret_val

ifdef WINDOWS then
	
	atom rootPathName, volSerNum

	if atom(root_dir) then						-- for cases of 'C', 'd', etc...
		root_dir = root_dir & ":\\"
	elsif length(root_dir) = 1 then 			-- for cases of "C", "D", etc...
		root_dir &= ":\\"
	elsif equal( root_dir[$], ':' ) then		-- for cases of "C:", "Z:", etc...
		root_dir &= SLASH
	elsif not equal( root_dir[$], SLASH ) then	-- for cases of "\\\\SERVER_NAME\\PATH"
		root_dir &= SLASH
	end if										-- anything else, I can't help you
	
	rootPathName    = allocate_string( root_dir )
	volSerNum       = allocate( 4 )

	if not c_func( xGetVolumeInfo, { rootPathName, NULL, NULL, volSerNum, NULL, NULL, NULL, NULL } ) then
		ret_val = -1
	else
		ret_val = peek4u( volSerNum )
	end if

	free( rootPathName )
	free( volSerNum )
	
elsedef

	-- is this functionality available on *NIX?
	ret_val = -1
	
end ifdef
	
return ret_val
end function
