namespace symstruct

include std/dll.e

integer next_offset = 0
function offset( atom data_type, integer use_offset = next_offset )
	integer this_offset = use_offset
	next_offset = use_offset + sizeof( data_type )
	return this_offset
end function

public constant
	ST_OBJ            = offset( E_OBJECT ), -- 0
	ST_NEXT           = offset( C_POINTER ), -- 4
	ST_NEXT_IN_BLOCK  = offset( C_POINTER ), -- 8
	ST_MODE           = offset( C_CHAR ), -- 12
	ST_SCOPE          = offset( C_CHAR ), -- 13
	ST_FILE_NO        = offset( C_CHAR ), -- 14,
	ST_DUMMY          = offset( C_CHAR ), -- 15,
	ST_TOKEN          = offset( C_INT ), -- 20,
	ST_NAME           = offset( C_POINTER ), --16,
	
	
	-- var:
	ST_DECLARED_IN    = offset( C_POINTER ), -- 24,
	
	-- block:
	ST_FIRST_LINE     = offset( C_INT, ST_DECLARED_IN ), -- 24,
	ST_LAST_LINE      = offset( C_INT ), -- 28,
	
	-- routine:
	ST_CODE           = offset( C_POINTER, ST_DECLARED_IN ), -- 24,
	ST_TEMPS          = offset( C_POINTER ), -- 36,
	ST_SAVED_PRIVATES = offset( C_POINTER ), --48,
	ST_BLOCK          = offset( C_POINTER ), --56
	ST_LINETAB        = offset( C_POINTER ), -- 28,
	ST_FIRSTLINE      = offset( C_UINT ), -- 32,
	ST_NUM_ARGS       = offset( C_UINT ), -- 40,
	ST_RESIDENT_TASK  = offset( C_INT ), --44,
	ST_STACK_SPACE    = offset( C_UINT ), -- 52,
	
	ST_ENTRY_SIZE = next_offset  -- size (bytes) of back-end symbol table entry
							 -- for interpreter. Fixed size for all entries.
-- source line table entry
public constant
	SL_SRC = offset( C_POINTER, 0 ),
	SL_LINE = offset( C_SHORT ),
	SL_FILE_NO = offset( C_CHAR ),
	SL_OPTIONS = offset( C_CHAR ),
	SL_MULTILINE = offset( C_INT ),
	SL_SIZE    = next_offset + remainder( next_offset, sizeof( C_POINTER ) ) -- padding
