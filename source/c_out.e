-- (c) Copyright - See License.txt
--
--****
-- == c_out.e: Translator Routines for outputting C code

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include global.e
include buildsys.e
include std/search.e

--****
-- === gtype values, TRANSLATOR

export constant
	--**
	-- initial value for ORing of types
	TYPE_NULL = 0,

	--**
	-- definitely in Euphoria integer form
	TYPE_INTEGER = 1,

	--**
	-- definitely in double form
	TYPE_DOUBLE = 2,

	--**
	-- a value stored as either an integer or a double
	TYPE_ATOM = 4,

	--**
	-- definitely a sequence
	TYPE_SEQUENCE = 8,

	--**
	-- could be unknown or anything
	TYPE_OBJECT = 16  

export constant
	TYPES_DS = {TYPE_DOUBLE, TYPE_SEQUENCE},
	TYPES_AO = {TYPE_ATOM, TYPE_OBJECT},
	TYPES_IAO = {TYPE_INTEGER, TYPE_ATOM, TYPE_OBJECT},
	TYPES_SO = {TYPE_SEQUENCE, TYPE_OBJECT},
	TYPES_IAD = {TYPE_INTEGER, TYPE_ATOM, TYPE_DOUBLE},
	TYPES_AS = {TYPE_ATOM, TYPE_SEQUENCE},
	TYPES_IS = {TYPE_INTEGER, TYPE_SEQUENCE},
	TYPES_OBNL = {TYPE_OBJECT, TYPE_NULL},
	$
	
export boolean emit_c_output = FALSE
export file c_code=-1, c_h
export integer main_name_num = 0, init_name_num = 0
export sequence novalue = {MININT, MAXINT} --, target= {0, 0}

--**
-- output a byte of C source code 
export procedure c_putc(integer c)
	if emit_c_output then
		puts(c_code, c)
		update_checksum( c )
	end if
end procedure

--**
-- output a string of C source code to the .h file 
export procedure c_hputs(sequence c_source)
	if emit_c_output then
		puts(c_h, c_source)    
	end if
end procedure

--**
-- output a string of C source code 
export procedure c_puts(sequence c_source)
	if emit_c_output then
		puts(c_code, c_source)
		update_checksum( c_source )
	end if
end procedure

--**
-- output C source code to a .h file with (one) 4-byte formatted value
export procedure c_hprintf(sequence format, integer value)
	if emit_c_output then
		printf(c_h, format, value)
	end if
end procedure

--**
-- output C source code with (one) 4-byte formatted value (should allow multiple values later)
export procedure c_printf(sequence format, object value)
	if emit_c_output then
		sequence text = sprintf( format, value )
		puts(c_code, text)
		update_checksum( text )
	end if
end procedure

constant CREATE_INF = "(1.0/sqrt(0.0))"
-- I don't think we need these currently. They can't happen at compile-time
-- because we don't fold f.p. operations
constant CREATE_NAN1 = "sqrt(-1.0)",
		 CREATE_NAN2 = "((1.0/sqrt(0.0)) / (1.0/sqrt(0.0)))"

--**
-- output C source code with (one) 8-byte formatted value
export procedure c_printf8(atom value)
	sequence buff
	integer neg, p
	
	if emit_c_output then
		neg = 0
		buff = sprintf("%.16e", value)
		if length(buff) < 10 then
			-- funny f.p. value
			p = 1
			while p <= length(buff) do
				if buff[p] = '-' then
					neg = 1

				elsif buff[p] = 'i' or buff[p] = 'I' then
					-- inf 
					buff = CREATE_INF
					if neg then
						buff = prepend(buff, '-')
					end if
					exit
				
				elsif buff[p] = 'n' or buff[p] = 'N' then
					-- NaN - not needed currently 
					ifdef UNIX then
						buff = CREATE_NAN1
						if neg then
							buff = prepend(buff, '-')
						end if
					elsedef
						if sequence(wat_path) then
							buff = CREATE_NAN2
							if not neg then
								buff = prepend(buff, '-')
							end if
						
						else 
							buff = CREATE_NAN1
							if neg then
								buff = prepend(buff, '-')
							end if
						end if
						exit
					end ifdef
				end if
				p += 1
			end while
		end if
		puts(c_code, buff)
	end if
end procedure

--**
-- long term indent with braces
export integer indent = 0

--**
-- just for next statement
export integer temp_indent = 0
constant big_blanks = "                                                        "
--**
-- Adjust indent before a statement
export procedure adjust_indent_before(sequence stmt)
	integer i
	boolean lb, rb
		
	lb = FALSE
	rb = FALSE
	
	for p = 1 to length(stmt) do
		switch stmt[p] do
			case '\n' then
				exit
				
			case  '}' then
				rb = TRUE
				if lb then
					exit
				end if
				
			case '{' then
				lb = TRUE
				if rb then 
					exit
				end if
				
		end switch
	end for
	
	if rb then
		if not lb then
			indent -= 4
		end if
	end if
	
	i = indent + temp_indent
	while i >= length(big_blanks) do
		c_puts(big_blanks)
		i -= length(big_blanks)
	end while

	c_puts(big_blanks[1..i])

	temp_indent = 0
end procedure

--**
-- Adjust indent after a statement
export procedure adjust_indent_after(sequence stmt)

	for p = 1 to length(stmt) do
		switch stmt[p] do
			case '\n' then
				exit
		
			case '{' then
				indent += 4
				return
		end switch
	end for
	
end procedure
