--****
-- == Universally Unique Identifiers (UUID)
--
-- <<LEVELTOC level=2 depth=4>>
--
-- Universally Unique Identifiers (UUID) provide identiy with near certainty that
-- the identifier does not duplicate one that has already been, or will be, created
-- to identify something else. Information labeled with UUIDs by independent parties
-- can therefore be later combined into a single database, or transmitted on the
-- same channel, with a negligible probability of duplication.
--
-- See [[https://en.wikipedia.org/wiki/Universally_unique_identifier|Universally_unique_identifier]]
-- for more information.

namespace uuid

include std/convert.e
include std/dll.e
include std/machine.e
include std/rand.e
include std/sequence.e
include std/types.e

constant SIZEOF_UUID = 16

constant UUID_FORMAT_PARTS = {
	{ 1, 2},{ 3, 4},{ 5, 6},{ 7, 8},{10,11},{12,13},{15,16},{17,18},
	{20,21},{22,23},{25,26},{27,28},{29,30},{31,32},{33,34},{35,36}}

constant UUID_FORMAT_STRING =
	"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x"

--**
-- The UUID is 16 bytes (128 bits) long, which gives approximately 3.4x10^38 unique
-- values (there are approximately 10^80 elementary particles in the universe according
-- to Carl Sagan's [[https://en.wikipedia.org/wiki/Cosmos_(Carl_Sagan_book)|Cosmos]]).
--
-- Parameters:
--   # ##obj## : any object
--
-- Comments:
--   A UUID must be exactly 16 bytes.
--
public type uuid_t( object obj )
	
	-- UUID must be a sequence
	if not sequence( obj ) then
		return FALSE
	end if
	
	-- UUID must be 16 bytes long
	if length( obj ) != SIZEOF_UUID then
		return FALSE
	end if
	
	-- each value must be only one byte
	for i = 1 to SIZEOF_UUID do
		if and_bits( obj[i], #FF ) != obj[i] then
			return FALSE
		end if
	end for
	
	return TRUE
end type

/*
 * Use Remote Procedure Call library on Windows, which should always be available.
 * Use libuuid on *NIX if it's available. Otherwise use our own internal routines.
 */
 
ifdef WINDOWS then
	
	atom rpcrt4 = open_dll( "Rpcrt4.dll" )
	
	constant xRpcStringFree   = define_c_func( rpcrt4, "RpcStringFreeA", {C_POINTER}, C_LONG )
	constant xUuidCreate      = define_c_func( rpcrt4, "UuidCreate", {C_POINTER}, C_LONG )
	constant xUuidFromString  = define_c_func( rpcrt4, "UuidFromStringA", {C_POINTER,C_POINTER}, C_LONG )
	constant xUuidToString    = define_c_func( rpcrt4, "UuidToStringA", {C_POINTER,C_POINTER}, C_LONG )
	
	constant RPC_S_OK = 0
	
elsedef
	
	ifdef OSX then
		atom libuuid = open_dll( "libuuid.dylib" )
	elsedef
		atom libuuid = open_dll( "libuuid.so" )
	end ifdef
	
	if libuuid = 0 then
		warning( "uuid.e: libuuid not found! using internal UUID routines instead." )
	end if
	
	constant SIZEOF_UUID_STRING = 36 + 1 -- 36 chars, 1 null terminator
	
	constant uuid_generate  = define_c_proc( libuuid, "uuid_generate", {C_POINTER} )
	constant uuid_parse     = define_c_func( libuuid, "uuid_parse", {C_POINTER,C_POINTER}, C_INT )
	constant uuid_unparse   = define_c_proc( libuuid, "uuid_unparse", {C_POINTER,C_POINTER} )
	
end ifdef

--**
-- Creates a new UUID.
--
-- Returns:
--   A **sequence**, a new 128-bit UUID value (16 bytes).
--
-- Comments:
--   If an error occurs, this function returns an empty sequence.
--
public function new()
	
	atom uuid = allocate_data( SIZEOF_UUID, TRUE )
	
ifdef WINDOWS then
	
	if c_func( xUuidCreate, {uuid} ) != RPC_S_OK then
		return {}
	end if
	
elsedef
	
	if libuuid != 0 then
		c_proc( uuid_generate, {uuid} )
		
	else
		sequence seeds = get_rand()
		set_rand( time() )
		
		poke2( uuid +  0,         rand_range(0, #FFFF) )
		poke2( uuid +  2,         rand_range(0, #FFFF) )
		poke2( uuid +  4,         rand_range(0, #FFFF) )
		poke2( uuid +  6, or_bits(rand_range(0, #0FFF), #4000) )
		poke2( uuid +  8, or_bits(rand_range(0, #3FFF), #8000) )
		poke2( uuid + 10,         rand_range(0, #FFFF) )
		poke2( uuid + 12,         rand_range(0, #FFFF) )
		poke2( uuid + 14,         rand_range(0, #FFFF) )
		
		set_rand( seeds )
		
	end if
	
end ifdef
	
	return peek({ uuid, SIZEOF_UUID })
end function

--**
-- Converts a 128-bit UUID value to its string representation.
--
-- Parameters:
--   # ##data## ~-- the 128-bit UUID value (16 bytes)
--
-- Returns:
--   A **sequence**, the string format of the UUID.
--
-- Comments:
--   If an error occurs, this function returns an empty string.
--
public function format( uuid_t data )
	
	string str = ""
	
ifdef WINDOWS then
	
	atom uuid = allocate_data( SIZEOF_UUID, TRUE )
	poke( uuid, data )
	
	atom buff = allocate_data( sizeof(C_POINTER), TRUE )
	
	if c_func( xUuidToString, {uuid,buff} ) != RPC_S_OK then
		return ""
	end if
		
	atom ptr = peek_pointer( buff )
	str = peek_string( ptr )
	
	c_func( xRpcStringFree, {ptr} )
	
elsedef
	
	if libuuid != 0 then
		
		atom uuid = allocate_data( SIZEOF_UUID, TRUE )
		poke( uuid, data )
		
		atom ptr = allocate_data( SIZEOF_UUID_STRING )
		c_proc( uuid_unparse, {uuid,ptr} )
		
		str = peek_string( ptr )
		
	else
		
		str = sprintf( UUID_FORMAT_STRING, data )
		
	end if
	
end ifdef
	
	return str
end function

--**
-- Parses a UUID string into its 128-bit value.
--
-- Parameters:
--   # ##str## ~-- a UUID in string format
--
-- Returns:
--   A **sequence**, the 128-bit UUID value (16 bytes).
--
-- Comments:
--   If an error occurs, this function returns an empty sequence.
--
public function parse( string str )
	
	uuid_t data
	
ifdef WINDOWS then
	
	atom ptr = allocate_string( str, TRUE )
	atom uuid = allocate_data( SIZEOF_UUID, TRUE )
	
	if c_func( xUuidFromString, {ptr,uuid} ) != RPC_S_OK then
		return {}
	end if
	
	data = peek({ uuid, SIZEOF_UUID })
	
elsedef
	
	if libuuid != 0 then
		
		atom ptr = allocate_string( str, TRUE )
		atom uuid = allocate_data( SIZEOF_UUID, TRUE )
		
		if c_func( uuid_parse, {ptr,uuid} ) != 0 then
			return {}
		end if
		
		data = peek({ uuid, SIZEOF_UUID })
		
	else
		
		sequence buff = stdseq:project( {str}, UUID_FORMAT_PARTS )
		
		data = repeat( 0, SIZEOF_UUID )
		
		for i = 1 to SIZEOF_UUID do
			data[i] = to_integer( '#' & buff[1][i] )
		end for
		
	end if
	
end ifdef
	
	return data
end function
