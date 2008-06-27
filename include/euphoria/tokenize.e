---------------------------------------------------------------------------------
-- eu_parse.e Â© CreativePortal.ca
-- version 0.2
--
-- mailto:code@creativeportal.ca
-- http://www.creativeportal.ca                          written by Chris Bensler
---------------------------------------------------------------------------------
include euphoria/keywords.e

integer enum_val,enum_inc
function Enum_Start(integer start, integer inc)
  enum_val = start
  enum_inc = inc
  return enum_val
end function

function Enum()
  enum_val += enum_inc
  return enum_val
end function

---------------------------------------------------------------------------------

global constant
    T_EOF         = -1
   ,T_NULL        = Enum_Start(0,1)
   ,T_BLANK       = Enum()
   ,T_COMMENT     = Enum()
   ,T_NUMBER      = Enum()
   ,T_CHAR        = Enum() -- quoted character
   ,T_STRING      = Enum() -- string
   ,T_IDENTIFIER  = Enum()
   ,T_KEYWORD     = Enum()

   ,T_DOUBLE_OPS  = Enum_Start(8,1) -- (should be 8) marks the start of the double-op delimiter codes
   ,T_PLUSEQ      = Enum_Start(8,1)
   ,T_MINUSEQ     = Enum()
   ,T_MULTIPLYEQ  = Enum()
   ,T_DIVIDEEQ    = Enum()
   ,T_LTEQ        = Enum()
   ,T_GTEQ        = Enum()
   ,T_NOTEQ       = Enum()
   ,T_CONCATEQ    = Enum()

   ,T_DELIMITER   = Enum_Start(16,1) -- (should be 16) marks the start of the delimiter codes
   ,T_PLUS        = Enum_Start(16,1)
   ,T_MINUS       = Enum()
   ,T_MULTIPLY    = Enum()
   ,T_DIVIDE      = Enum()
   ,T_LT          = Enum()
   ,T_GT          = Enum()
   ,T_NOT         = Enum()
   ,T_CONCAT      = Enum()
   ,T_SINGLE_OPS  = Enum_Start(24,1) -- (should be 24) marks the start of the single-op delimiter codes
   ,T_EQ          = Enum_Start(24,1)
   ,T_LPAREN      = Enum()
   ,T_RPAREN      = Enum()
   ,T_LBRACE      = Enum()
   ,T_RBRACE      = Enum()
   ,T_LBRACKET    = Enum()
   ,T_RBRACKET    = Enum()
   ,T_QPRINT      = Enum() -- quick print ( ? x )
   ,T_COMMA       = Enum()
   ,T_PERIOD      = Enum()
   ,T_COLON       = Enum()   
   ,T_DOLLAR      = Enum()
   ,T_SLICE       = Enum()

constant Delimiters = "+-*/<>!&" & "=(){}[]?,.:$" -- double & single ops

---------------------------------------------------------------------------------

global constant
            TTYPE = Enum_Start(1,1)
           ,TDATA = Enum()
           ,TLNUM = Enum()
           ,TLPOS = Enum()

sequence Token         Token = {-1,"",0,0}

---------------------------------------------------------------------------------

integer  ascanFN        ascanFN = -1
integer  ascanLNum      ascanLNum = 0
integer  ascanLPos      ascanLPos = 0
integer  ascanLook      ascanLook = '\n'

integer ERR         ERR       = 0
integer ERR_LNUM    ERR_LNUM  = 0
integer ERR_LPOS    ERR_LPOS  = 0

global constant
      ERR_OPEN = Enum_Start(1,1)
     ,ERR_ESCAPE = Enum()
     ,ERR_EOL_CHAR = Enum()
     ,ERR_CLOSE_CHAR = Enum()
     ,ERR_EOL_STRING = Enum()
     ,ERR_HEX = Enum()
     ,ERR_DECIMAL = Enum()
     ,ERR_UNKNOWN = Enum()
     ,ERR_EOF = Enum()

constant ERROR_STRING = {
      "Failed to open file"
     ,"Expected an escape character"
     ,"End of line reached without closing \' char"
     ,"Expected a closing \' char"
     ,"End of line reached without closing \" char"
     ,"Expected a hex value"
     ,"Expected a decimal value"
     ,"Unknown token type"
     ,"Expected EOF"
}

---------------------------------------------------------------------------------

procedure report_error(integer err)
  ERR = err
  ERR_LNUM = Token[TLNUM]
  ERR_LPOS = Token[TLPOS]
end procedure

global function eu_parse_error_string(integer err)
  if err >= ERR_OPEN and err <= ERR_EOF then
    return ERROR_STRING[err]
  else
    return ""
  end if
end function

---------------------------------------------------------------------------------

integer IGNORE_BLANKS       IGNORE_BLANKS = 1
integer IGNORE_COMMENTS     IGNORE_COMMENTS = 1
integer STRING_NUMBERS      STRING_NUMBERS = 0

global procedure eu_parse_blanks(integer toggle)
  IGNORE_BLANKS = not toggle
end procedure

global procedure eu_parse_comments(integer toggle)
  IGNORE_COMMENTS = not toggle
end procedure

global procedure eu_parse_stringnumbers(integer toggle)
  STRING_NUMBERS = toggle
end procedure

---------------------------------------------------------------------------------

procedure close_parse()
  if (ascanFN != -1) then close(ascanFN) end if
  ascanFN = -1
end procedure

procedure open_parse(sequence fname)
  if ascanFN != -1 then close_parse() end if
  ascanFN = open(fname,"rb")
  if ascanFN = -1 then
    report_error(ERR_OPEN)
    return
  end if
  ascanLNum = 1
  ascanLPos = 1
  ascanLook = getc(ascanFN)
  Token[TTYPE] = -1
  Token[TDATA] = ""
  Token[TLNUM] = 1
  Token[TLPOS] = 1
end procedure

---------------------------------------------------------------------------------
-- CHAR TYPE ROUTINES --

type Digit_Char(object c)
  return ('0' <= c) and (c <= '9')
end type

type uHex_Char(object c)
  return ('A' <= c) and (c <= 'F')
end type

type lHex_Char(object c)
  return ('a' <= c) and (c <= 'f')
end type

type Hex_Char(object c)
  return Digit_Char(c) or uHex_Char(c) or lHex_Char(c)
end type

type uAlpha_Char(object c)
  return ('A' <= c) and (c <= 'Z')
end type

type lAlpha_Char(object c)
  return ('a' <= c) and (c <= 'z')
end type

type Alpha_Char(object c)
  return uAlpha_Char(c) or lAlpha_Char(c)
end type

type Alphanum_Char(object c)
  return Alpha_Char(c) or Digit_Char(c)
end type

type Identifier_Char(object c)
  return Alphanum_Char(c) or (c = '_')
end type

---------------------------------------------------------------------------------

procedure scan_char()
  if ascanLook = '\n' then
    ascanLNum +=1
    ascanLPos = 0
  else
  end if
  ascanLPos +=1
  ascanLook = getc(ascanFN)
end procedure

function scan_white()
 integer lastLF
  Token[TTYPE] = T_BLANK
  Token[TDATA] = ""
  lastLF = (ascanLook = '\n')
  while (ascanLook >= 0) and (ascanLook <= ' ') do
    scan_char()
    if lastLF and (ascanLook = '\n') then
      return 1
    end if
  end while
  return 0
end function

procedure scan_comment()
  Token[TTYPE] = T_COMMENT
  Token[TDATA] = "--"
  while (ascanLook != '\n') do
    Token[TDATA] &= ascanLook
    scan_char()
  end while
end procedure

constant QFLAGS = "trn\\\'\""

procedure scan_escaped_char()
 integer f
  Token[TDATA] &= ascanLook
  if (ascanLook = '\\') then
    scan_char()
    f = find(ascanLook,QFLAGS)
    if not f then report_error(ERR_ESCAPE) return end if
    Token[TDATA] &= ascanLook
  end if
  scan_char()
end procedure

function scan_qchar()
  if (ascanLook != '\'') then return 0 end if
  scan_char()
  Token[TTYPE] = T_CHAR
  Token[TDATA] = ""
  if (ascanLook = '\n') then report_error(ERR_EOL_CHAR) return 1 end if
  scan_escaped_char()
  if ERR then return 1 end if
  if (ascanLook != '\'') then report_error(ERR_CLOSE_CHAR) return 1 end if
  scan_char()
  return 1
end function

function scan_string()
  if (ascanLook != '\"') then return 0 end if
  scan_char()
  Token[TTYPE] = T_STRING
  Token[TDATA] = ""
  while (ascanLook != '\"') do
    if (ascanLook = '\n') then report_error(ERR_EOL_STRING) return 1 end if
    scan_escaped_char()
    if ERR then return 1 end if
  end while
  scan_char()
  return 1
end function

function hex_val(integer h)
  if h >= 'a' then h -= ' ' end if
  if h >= 'A' then
    return h-'A'+10
  else
    return h-'0'
  end if
end function

function scan_hex()
  if (ascanLook != '#') then return 0 end if
  scan_char()
  if not Hex_Char(ascanLook) then report_error(ERR_HEX) return 1 end if
  Token[TTYPE] = T_NUMBER
  Token[TDATA] = hex_val(ascanLook)
  scan_char()
  while Hex_Char(ascanLook) do
    Token[TDATA] = Token[TDATA]*16 + hex_val(ascanLook)
    scan_char()
  end while
  if STRING_NUMBERS then Token[TDATA] = sprintf("#%x",{Token[TDATA]}) end if
  return 1
end function

integer SUBSCRIPT   SUBSCRIPT = 0
function scan_integer()
 atom i
  i = 0
  while Digit_Char(ascanLook) do
    i = (i*10) + (ascanLook-'0')
    scan_char()
  end while
  return i
end function

function scan_fraction(atom v)
 atom d
  if (ascanLook != '.') then return v end if
  scan_char()

  if not Digit_Char(ascanLook) then report_error(ERR_DECIMAL) return 0 end if
  
  d = 10
  while Digit_Char(ascanLook) do
    v += (ascanLook-'0')/d
    d *= 10
    scan_char()
  end while
  return v
end function

function scan_exponent(atom v)
 atom e
  if ((ascanLook != 'e') and (ascanLook != 'E')) then return v end if
  scan_char()

  if (ascanLook = '-') then
    e = -scan_integer()
    scan_char()
  elsif (ascanLook = '+') then
    e = scan_integer()
    scan_char()
  end if

  if e > 308 then
    v *= power(10,308)
    if e > 1000 then e = 1000 end if
    for i = 1 to e-308 do
      v *=10
    end for
  else
    v *= power(10,e)
  end if
  return v
end function

function scan_number()
  if not Digit_Char(ascanLook) then return 0 end if
  Token[TTYPE] = T_NUMBER
  Token[TDATA] = scan_integer()
  if not SUBSCRIPT then
    Token[TDATA] = scan_fraction(Token[TDATA])
    if ERR then return 1 end if
    Token[TDATA] = scan_exponent(Token[TDATA])
  end if
  if STRING_NUMBERS then Token[TDATA] = sprintf("%g",{Token[TDATA]}) end if
  return 1
end function

function scan_identifier()
  if not Alpha_Char(ascanLook) then return 0 end if
  Token[TTYPE] = T_IDENTIFIER
  Token[TDATA] = ""
  while Identifier_Char(ascanLook) do
    Token[TDATA] &= ascanLook
    scan_char()
  end while
  if find(Token[TDATA],keywords) then
    Token[TTYPE] = T_KEYWORD
  end if
  return 1
end function

procedure next_token()
  Token[TLNUM] = ascanLNum
  Token[TLPOS] = ascanLPos
  if scan_white() then
    if IGNORE_BLANKS then next_token() end if
    return
  end if

  Token[TTYPE] = find(ascanLook,Delimiters)
  if Token[TTYPE] then
    Token[TTYPE] += T_DELIMITER-1
    Token[TDATA] = ascanLook
    scan_char()
    if (ascanLook = '=') then -- check for double operators: += -= *= /= etc..
      if (Token[TTYPE] <= T_SINGLE_OPS) then
        Token[TTYPE] -= T_DOUBLE_OPS
        Token[TDATA] &= ascanLook
        scan_char()
      end if
    elsif (ascanLook = '.') then -- check for slice operator: ..
      if (Token[TTYPE] = T_PERIOD) then
        Token[TTYPE] = T_SLICE
        Token[TDATA] &= ascanLook
        scan_char()
      else
        Token[TTYPE] = T_NUMBER
        Token[TDATA] = scan_fraction(0)
        if ERR then return end if
        Token[TDATA] = scan_exponent(Token[TDATA])
        if STRING_NUMBERS then Token[TDATA] = sprintf("%g",{Token[TDATA]}) end if
      end if
    elsif (ascanLook = '-') then -- check for comment: --
      scan_char()
      scan_comment()
      if IGNORE_COMMENTS then next_token() end if
    elsif (Token[TTYPE] = T_LBRACKET) then
      SUBSCRIPT += 1
    elsif (Token[TTYPE] = T_RBRACKET) then
      SUBSCRIPT -= 1
    end if
  elsif scan_qchar() then
  elsif scan_string() then
  elsif scan_hex() then
  elsif scan_number() then
  elsif scan_identifier() then
  else
    Token[TTYPE] = T_EOF
    Token[TDATA] = ascanLook
    if (ascanLook != -1) then report_error(ERR_UNKNOWN) end if
  end if
end procedure

global function eu_parse(sequence fname)
 sequence tokens

  ERR = 0
  ERR_LNUM = 0
  ERR_LPOS = 0

  tokens = {}
  open_parse(fname)
  if not ERR then
  
    next_token()
    if not ERR then
      while Token[TTYPE] != T_EOF do
        tokens &={ Token }
        next_token()
        if ERR then exit end if
      end while
      if not ERR and (Token[TTYPE] != T_EOF) then report_error(ERR_EOF) end if
    end if
  
    close_parse()
  end if
  
  return {tokens,ERR,ERR_LNUM, ERR_LPOS}
end function
