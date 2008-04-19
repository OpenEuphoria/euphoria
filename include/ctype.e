-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Character type testing routines

global function isalnum(atom chr)
    return ( chr >= '0' and chr <= '9' ) or
        ( chr >= 'a' and chr <= 'z' ) or
        ( chr >= 'A' and chr <= 'Z' )
end function

global function isalpha(atom chr)
    return ( chr >= 'a' and chr <= 'z' ) or
        ( chr >= 'A' and chr <= 'Z' )
end function

global function isascii(atom chr)
    return ( chr >= 0 and chr <= 127 )
end function

global function iscntrl(atom chr)
    return ( chr >= 0 and chr <= 31 ) or chr = 127
end function

global function isdigit(atom chr)
    return ( chr >= '0' and chr <= '9' )
end function

global function isgraph(atom chr)
    return ( chr >= '!' and chr <= '~' )
end function

global function islower(atom chr)
    return ( chr >= 'a' and chr <= 'z' )
end function

global function isprint(atom chr)
    return ( chr >= ' ' and chr <= '~' )
end function

global function ispunct(atom chr)
    return ( chr >= ' ' and chr <= '/' ) or
        ( chr >= ':' and chr <= '?' ) or
        ( chr >= '[' and chr <= '`' ) or
        ( chr >= '{' and chr <= '~' )
end function

global function isspace(atom chr)
    return chr = ' ' or chr = '\t' or chr = '\n' or chr = '\r' or chr = 11
end function

global function isupper(atom chr)
    return ( chr >= 'A' and chr <= 'Z' )
end function

global function isxdigit(atom chr)
    return ( chr >= '0' and chr <= '9' ) or
        ( chr >= 'A' and chr <= 'F' ) or
        ( chr >= 'a' and chr <= 'f' )
end function
