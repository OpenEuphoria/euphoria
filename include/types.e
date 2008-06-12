-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category: 
--   type
--
-- Title:
--   Extended Types
--****
--

global constant
	FALSE = 0,
	TRUE  = 1

global type bool(object val)
	return val = 1 or val = 0
end type

global type t_alnum(object chr)
	return ( chr >= '0' and chr <= '9' ) or
		( chr >= 'a' and chr <= 'z' ) or
		( chr >= 'A' and chr <= 'Z' )
end type

global type t_alpha(object chr)
	return ( chr >= 'a' and chr <= 'z' ) or
		( chr >= 'A' and chr <= 'Z' )
end type

global type t_ascii(object chr)
	return ( chr >= 0 and chr <= 127 )
end type

global type t_cntrl(object chr)
	return ( chr >= 0 and chr <= 31 ) or chr = 127
end type

global type t_digit(object chr)
	return ( chr >= '0' and chr <= '9' )
end type

global type t_graph(object chr)
	return ( chr >= '!' and chr <= '~' )
end type

global type t_lower(object chr)
	return ( chr >= 'a' and chr <= 'z' )
end type

global type t_print(object chr)
	return ( chr >= ' ' and chr <= '~' )
end type

global type t_punct(object chr)
	return ( chr >= ' ' and chr <= '/' ) or
		( chr >= ':' and chr <= '?' ) or
		( chr >= '[' and chr <= '`' ) or
		( chr >= '{' and chr <= '~' )
end type

global type t_space(object chr)
	return chr = ' ' or chr = '\t' or chr = '\n' or chr = '\r' or chr = 11
end type

global type t_upper(object chr)
	return ( chr >= 'A' and chr <= 'Z' )
end type

global type t_xdigit(object chr)
	return ( chr >= '0' and chr <= '9' ) or
		( chr >= 'A' and chr <= 'F' ) or
		( chr >= 'a' and chr <= 'f' )
end type

