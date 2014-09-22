-- (c) Copyright - See License.txt

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/map.e as map

include common.e
include global.e
include symtab.e
include shift.e
include error.e
include opnames.e
include reswords.e
include emit.e

enum
	BLOCK_SYM,
	BLOCK_OPCODE,
	BLOCK_LABEL,
	BLOCK_START,
	BLOCK_END,
	BLOCK_VARS,
	
	BLOCK_SIZE

enum
	VAR_BLOCK,
	VAR_SYM

export enum
	LOOP_BLOCK,
	CONDITIONAL_BLOCK

-- 	TODO: The map usage here ultimately causes a task to be
--        created, which causes problems, since the be_task
--        that is linked against the translated version is
--        meant to be used with interpreted code.
-- map:map map_links = map:new()

sequence block_stack = { repeat( 0, BLOCK_SIZE - 1 ) } -- track nested blocks
block_stack[1][BLOCK_VARS] = {}

export symtab_index 
	current_block = 0, top_level_block = -1

function block_type_name( integer opcode )
	switch opcode do
		case LOOP then
			return "LOOP"
		case PROC then
			return "PROC"
		case FUNC then
			return "FUNC"
		case else
			return opnames[opcode]
		end switch
end function

procedure check_block( integer got )
	integer expected = block_stack[$][BLOCK_OPCODE]
	if got = FUNC then
		got = PROC
	end if
	if got != expected then
		CompileErr( EXPECTED_END_OF_1_BLOCK_NOT_2, {block_type_name( expected ), block_type_name( got)} )
	end if
end procedure

export procedure Block_var( symtab_index sym )
-- Adds the specified var to the current block
	sequence block = block_stack[$]
	block_stack[$] = 0
	if length(block_stack) > 1 then
		-- don't record for top level blocks
		SymTab[sym][S_BLOCK] = block[BLOCK_SYM]
	end if
	
	if length(block[BLOCK_VARS]) then
		SymTab[block[BLOCK_VARS][$]][S_NEXT_IN_BLOCK] = sym
	else
		SymTab[block[BLOCK_SYM]][S_NEXT_IN_BLOCK] = sym
	end if
	
	block[BLOCK_VARS] &= sym
	
	block_stack[$] = block
	ifdef BDEBUG then
		if length(SymTab[sym]) >= S_NAME then
			printf(1, "\tblock var: %s\n", {SymTab[sym][S_NAME]})
		end if
	end ifdef
end procedure

procedure NewBlock( integer opcode, object block_label )
-- creates a SymTab entry for the new block and returns the symtab_index

	SymTab = append( SymTab, repeat( 0, SIZEOF_BLOCK_ENTRY ) )
	SymTab[$][S_MODE] = M_BLOCK
	SymTab[$][S_FIRST_LINE] = gline_number
	
	sequence block = repeat( 0, BLOCK_SIZE-1 )
	block[BLOCK_SYM]    = length(SymTab)
	block[BLOCK_OPCODE] = opcode
	block[BLOCK_LABEL]  = block_label
	block[BLOCK_START]  = length(Code) + 1
	block[BLOCK_VARS]   = {}
	
	block_stack = append( block_stack, block )
	current_block = length(SymTab)
end procedure


export procedure Start_block( integer opcode, object block_label = 0 )
-- creates a new block and pushes it onto the block_stack

	symtab_index last_block = current_block
	if opcode = FUNC then
		opcode = PROC
	end if
	NewBlock( opcode, block_label )
	
	if find(opcode, RTN_TOKS) then
		SymTab[block_label][S_BLOCK] = current_block
		SymTab[current_block][S_NAME] = sprintf("BLOCK: %s", {SymTab[block_label][S_NAME]})
	elsif current_block then
-- 	TODO: The map usage here ultimately causes a task to be
--        created, which causes problems, since the be_task
--        that is linked against the translated version is
--        meant to be used with interpreted code.
-- 		map:put( map_links, last_block, current_block, map:CONCAT )
		SymTab[current_block][S_BLOCK] = last_block
		sequence label_name = ""
		if sequence(block_label) then
			label_name = block_label
		end if
		
		SymTab[current_block][S_NAME] = sprintf( "BLOCK: %s-%s", {block_type_name(opcode), label_name})
	end if
	
	ifdef BDEBUG then
		if find( opcode, RTN_TOKS) then
			printf(1,"Entering block for routine %s[%d]\n", {SymTab[block_label][S_NAME],current_block})
		elsif opcode then
			printf(1,"Entering block for %s block %s[%d]\n", {opnames[opcode], block_label, current_block})
		else
			puts(1,"Entering block with no opcode!?\n")
		end if
	end ifdef
end procedure

export procedure block_label( sequence label_name )
-- sets the label for the current block
	block_stack[$][BLOCK_LABEL] = label_name
	SymTab[current_block][S_NAME] = sprintf( "BLOCK: %s-%s", 
		{ block_type_name(block_stack[$][BLOCK_OPCODE]), label_name})
end procedure

function pop_block()
-- pops the top block off the stack and hides its variables.
	if not length(block_stack) then
		return 0
	end if
	
	sequence  block = block_stack[$]
	block_stack = block_stack[1..$-1]
	SymTab[block[BLOCK_SYM]][S_LAST_LINE] = gline_number
	
	ifdef BDEBUG then
		printf(1,"Popping block %s\n", {SymTab[block[BLOCK_SYM]][S_NAME]})
		? block[BLOCK_VARS]
	end ifdef
	-- now hide the variables
	sequence block_vars = block[BLOCK_VARS]
	for sx = 1 to length( block_vars ) do
		
		if SymTab[block_vars[sx]][S_MODE] = M_NORMAL 
		and SymTab[block_vars[sx]][S_SCOPE] <= SC_LOCAL then
			ifdef BDEBUG then
				if length(SymTab[block_vars[sx]]) >= S_NAME then
					printf(1,"\tHiding %s\n", {SymTab[block_vars[sx]][S_NAME]})
				end if
			end ifdef
			Hide( block_vars[sx] )
			LintCheck( block_vars[sx] )
		end if
		
	end for
-- 	TODO: The map usage here ultimately causes a task to be
--        created, which causes problems, since the be_task
--        that is linked against the translated version is
--        meant to be used with interpreted code.
-- 	if not length(block_vars) label "empty block" then
-- 		-- this is an empty block...remove it
-- 		symtab_index bsym  = sym_block( CurrentSub )
-- 		symtab_index empty = block[BLOCK_SYM]
-- 		if bsym = empty then
-- 			break
-- 		end if
-- 		object linked_blocks = map:get( map_links, empty, {} )
-- 		if atom(linked_blocks) then
-- 			linked_blocks = {linked_blocks}
-- 		end if
-- 		for i = 1 to length( linked_blocks ) do
-- 			SymTab[linked_blocks[i]][S_BLOCK] = bsym
-- 		end for
-- 		map:put( map_links, bsym, linked_blocks, map:CONCAT )
-- 		
-- 	end if
	current_block = block_stack[$][BLOCK_SYM]
	return block[BLOCK_SYM]
end function

export function top_block( integer offset = 0 )
-- Returns the sym to the block at $-offset
	if offset >= length(block_stack) then
		CompileErr(LEAVING_TOO_MANY_BLOCKS_1__2, {offset,length(block_stack)})
	else
		return block_stack[$-offset][BLOCK_SYM]
	end if
end function

export procedure End_block( integer opcode )
-- Emits an EXIT_BLOCK if the block is not empty, and
-- pops the top block from the stack.
	if opcode = FUNC then
		opcode = PROC
	end if
	check_block( opcode )
	if not length(block_stack[$][BLOCK_VARS]) then
		integer ix = 1
		ix = pop_block()
	else
		Push( pop_block() )
		emit_op( EXIT_BLOCK )
	end if
	
end procedure

export function End_inline_block( integer opcode )
-- returns code to be emitted in the epilog of an inlined
-- routine, and pops the block for the routine
	if opcode = FUNC then
		opcode = PROC
	end if
	if length(block_stack[$][BLOCK_VARS]) then
		return { EXIT_BLOCK, pop_block() }
	else
		Drop_block( opcode )
		return {}
	end if
	
end function

export procedure Sibling_block( integer opcode )
-- Ends the current block, and immediately pushes another.
-- This is intended for if-elsifs or for cases without fallthru.
	End_block( opcode )
	Start_block( opcode )
end procedure


procedure Leave_block( integer offset )
-- Emits an EXIT_BLOCK for the block $-offset
	if length( block_stack[$-offset][BLOCK_VARS]) then
		Push( top_block( offset ) )
		emit_op( EXIT_BLOCK )
	end if
end procedure

function Block_opcode( integer bx )
-- returns the opcode of the block at offset $-bx
	return block_stack[$-bx][BLOCK_OPCODE]
end function

export procedure Leave_blocks( integer blocks, integer block_type = 0 )
-- Emits EXIT_BLOCK ops, but does not end the blocks.
-- If block_type = 0, then just leaves the top 'blocks' blocks.
-- Otherwise, it leaves the top 'blocks' blocks matchin the block_type,
-- which can be either LOOP_BLOCK or CONDITIONAL_BLOCK.
	integer bx = 0
	while blocks do
		Leave_block( bx )
		
		if block_type then
			switch Block_opcode( bx ) do
				case FOR, WHILE, LOOP then
					if block_type = LOOP_BLOCK then
						blocks -= 1
					end if
				case else
					if block_type = CONDITIONAL_BLOCK then
						blocks -= 1
					end if
			end switch
		else
			blocks -= 1
		end if
		bx += 1
	end while
	for i = 0 to blocks - 1 do
		Leave_block( i )
	end for
end procedure

export procedure Drop_block( integer opcode )
-- Pops the current block off the stack without emitting an EXIT_BLOCK
	check_block( opcode )
	symtab_index x = pop_block()
end procedure

export procedure Pop_block_var()
	symtab_index sym = block_stack[$][BLOCK_VARS][$]
	symtab_index block_sym = block_stack[$][BLOCK_SYM]
	while sym_next_in_block( block_sym ) != sym do
		block_sym = sym_next_in_block( block_sym )
	end while
	
	SymTab[block_sym][S_NEXT_IN_BLOCK] = sym_next_in_block( sym )
	SymTab[sym][S_NEXT_IN_BLOCK] = 0
	
	block_stack[$][BLOCK_VARS] = eu:remove( block_stack[$][BLOCK_VARS], 
		length(block_stack[$][BLOCK_VARS]) )
end procedure

export procedure Goto_block( symtab_index from_block, symtab_index to_block, integer pc = 0 )
	sequence code = {}
	symtab_index next_block = sym_block( from_block )
	while next_block 
	and from_block != to_block 
	and not find( sym_token( next_block ), RTN_TOKS ) do
		code &= { EXIT_BLOCK, from_block }
		from_block = next_block
		next_block = sym_block( next_block )
	end while
	
	if length(code) then
		if pc then
			insert_code( code, pc )
		else
			Code &= code
		end if
	end if
	
end procedure

export procedure blocks_info()
	? block_stack
end procedure

--**
-- Used to find the block that a return statement should
-- use.  It should disregard empty blocks.
export function Least_block()
	integer ix = length( block_stack )
	symtab_index sub_block = sym_block( CurrentSub )
	while not length( block_stack[ix][BLOCK_VARS] ) 
	and block_stack[ix][BLOCK_SYM] != sub_block do
		ix -= 1	
	end while
	return block_stack[ix][BLOCK_SYM]
end function
