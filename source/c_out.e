-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Translator Routines for outputting C code

include global.e

-- gtype values, TRANSLATOR:
global constant TYPE_NULL = 0,    -- initial value for ORing of types
	 TYPE_INTEGER = 1, -- definitely in Euphoria integer form
	 TYPE_DOUBLE = 2,  -- definitely in double form
	 TYPE_ATOM = 4,    -- a value stored as either an integer or a double
	 TYPE_SEQUENCE = 8,-- definitely a sequence 
	 TYPE_OBJECT = 16  -- could be unknown or anything 

global boolean emit_c_output
emit_c_output = FALSE

global file c_code, c_h

global integer main_name_num, init_name_num
main_name_num = 0
init_name_num = 0

global sequence novalue, target
novalue = {MININT, MAXINT}
target = {0, 0}

global procedure c_putc(integer c)
-- output a byte of C source code 
    if emit_c_output then
	puts(c_code, c)
    end if
end procedure

global procedure c_hputs(sequence c_source)
-- output a string of C source code to the .h file 
    if emit_c_output then
	puts(c_h, c_source)    
    end if
end procedure

global procedure c_puts(sequence c_source)
-- output a string of C source code 
    if emit_c_output then
	puts(c_code, c_source)
    end if
end procedure

global procedure c_hprintf(sequence format, integer value)
-- output C source code to a .h file with (one) 4-byte formatted value
    if emit_c_output then
	printf(c_h, format, value)
    end if
end procedure

global procedure c_printf(sequence format, integer value)
-- output C source code with (one) 4-byte formatted value (should allow multiple values later)
    if emit_c_output then
	printf(c_code, format, value)
    end if
end procedure

constant CREATE_INF = "(1.0/sqrt(0.0))"
-- I don't think we need these currently. They can't happen at compile-time
-- because we don't fold f.p. operations
constant CREATE_NAN1 = "sqrt(-1.0)",
	 CREATE_NAN2 = "((1.0/sqrt(0.0)) / (1.0/sqrt(0.0)))"

global procedure c_printf8(atom value)
-- output C source code with (one) 8-byte formatted value 
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
		    if ELINUX then
			buff = CREATE_NAN1
			if neg then
			    buff = prepend(buff, '-')
			end if
		    else
			if sequence(wat_path) or sequence(bor_path) then
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
		    end if
		end if
		p += 1
	    end while
	end if
	puts(c_code, buff)
    end if
end procedure


global integer indent       -- long term indent with braces
indent = 0
global integer temp_indent  -- just for next statement
temp_indent = 0

global procedure adjust_indent_before(sequence stmt)
-- adjust indent before a statement 
    integer p, i
    boolean lb, rb
    
    if not emit_c_output then
	return
    end if
    
    p = 1
    lb = FALSE
    rb = FALSE
    while p <= length(stmt) and stmt[p] != '\n' do
	if stmt[p] = '}' then
	    rb = TRUE
	elsif stmt[p] = '{' then
	    lb = TRUE
	end if
	p += 1
    end while
    if rb and not lb then
	indent -= 4
    end if
    
    i = indent + temp_indent
    while i >= 4 do
	c_puts("    ")
	i -= 4
    end while
    while i > 0 do 
	c_putc(' ')
	i -= 1
    end while
    temp_indent = 0    
end procedure

global procedure adjust_indent_after(sequence stmt)
-- adjust indent after a statement 
    integer p
    
    if not emit_c_output then
	return
    end if
    
    p = 1
    while p <= length(stmt) and stmt[p] != '\n' do
	if stmt[p] = '{' then
	    indent += 4
	    return
	end if
	p += 1
    end while
    if length(stmt) >= 3 and equal("if ", stmt[1..3]) then
	temp_indent = 4
    elsif length(stmt) >= 5 and equal("else", stmt[1..4]) and
	  (stmt[5] = ' ' or stmt[5] = '\n') then
	temp_indent = 4
    end if
end procedure

