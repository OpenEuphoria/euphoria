namespace symstruct

include std/dll.e

integer next_offset = 0
function offset( atom data_type, integer use_offset = next_offset )
	integer this_offset = use_offset
	next_offset = use_offset + sizeof( data_type )
	return this_offset
end function

public constant
	ST_OBJ            = offset( E_OBJECT ), 
	ST_NEXT           = offset( C_POINTER ), 
	ST_NEXT_IN_BLOCK  = offset( C_POINTER ), 
	ST_MODE           = offset( C_CHAR ), 
	ST_SCOPE          = offset( C_CHAR ), 
	ST_FILE_NO        = offset( C_CHAR ), 
	ST_DUMMY          = offset( C_CHAR ), 
	ST_TOKEN          = offset( C_INT ), 
	ST_NAME           = offset( C_POINTER ), 
	
	
	
	ST_DECLARED_IN    = offset( C_POINTER ), 
	ST_LITERAL_SET    = offset( C_POINTER ), 
	ST_LS_ACCESS_METHOD = offset( C_INT ),   
	
	
	ST_FIRST_LINE     = offset( C_INT, ST_DECLARED_IN ), 
	ST_LAST_LINE      = offset( C_INT ), 
	
	
	ST_CODE           = offset( C_POINTER, ST_DECLARED_IN ), 
	ST_TEMPS          = offset( C_POINTER ), 
	ST_SAVED_PRIVATES = offset( C_POINTER ), 
	ST_BLOCK          = offset( C_POINTER ), 
	ST_LINETAB        = offset( C_POINTER ), 
	ST_FIRSTLINE      = offset( C_UINT ), 
	ST_NUM_ARGS       = offset( C_UINT ), 
	ST_RESIDENT_TASK  = offset( C_INT ), 
	ST_STACK_SPACE    = offset( C_UINT ), 
	
	ST_ENTRY_SIZE = next_offset  -- size (bytes) of back-end symbol table entry
							 -- for interpreter. Fixed size for all entries.
-- source line table entry
public constant
	SL_SRC = offset( C_POINTER, 0 ),
	SL_LINE = offset( C_SHORT ),
	SL_FILE_NO = offset( C_CHAR ),
	SL_OPTIONS = offset( C_CHAR ),
	SL_SIZE    = next_offset + remainder( next_offset, sizeof( C_POINTER ) ) -- padding
