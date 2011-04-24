namespace debug

--****
-- == Debugging tools
--
-- <<LEVELTOC level=2 depth=4>>

constant M_CALL_STACK = 103

-- ****
-- === Debugging Constants

-- ****
-- ==== Call Stack Constants

public enum
--** CS_ROUTINE_NAME: index of the routine name in the sequence returned by [[:call_stack]]
	CS_ROUTINE_NAME,
--** CS_FILE_NAME: index of the file name in the sequence returned by [[:call_stack]]
	CS_FILE_NAME,
--** CS_LINE_NO: index of the line number in the sequence returned by [[:call_stack]]
	CS_LINE_NO,
	$

-- ****
-- === Debugging Routines

-- **
-- Description:
-- Returns information about the call stack of the code currently running.
-- 
-- Returns:
-- A sequence where each element represents one level in the call stack.  See the
-- [[:Call Stack Constants]] for constants that can be used to access the call stack
-- information.
-- # routine name
-- # file name
-- # line number
public function call_stack()
	return machine_func( M_CALL_STACK, {} )
end function
