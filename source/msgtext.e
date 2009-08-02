include std/filesys.e
include std/locale.e

include common.e

constant StdErrMsgs = {
	{  0, "Unknown message code"},
	{  1, "%s is missing defined word before 'or'"},
	{  2, "%s is missing defined word before 'and'"},
	{  3, "%s word must be an identifier"},
	{  4, "%s not understood"},
	{  5, "%s is not supported in Euphoria for %s"},
	{  6, "%s is missing defined word before 'then'"},
	{  7, "%s duplicate 'not'"},
	{  8, "%s 'then' follows '%s'"},
	{  9, "%s 'or' follows '%s'"},
	{ 10, "%s 'and' follows '%s'"},
	{ 11, "%s 'then' follows 'not'"},
	{ 12, "%s conflicts with a file name used internally by the Translator"},
	{ 13, "'with fallthru' is only valid in a switch statement"},
	{ 14, "'with entry' is only valid on a while or loop statement"},
	{ 15, "'without fallthru' is only valid in a switch statement"},
	{ 16, "'public' or 'export' must be followed by:\n<a type>, 'constant', 'enum', 'procedure', 'type' or 'function'"},
	{ 17, "'end' has no matching '%s'"},
	{ 18, "'global' must be followed by:\n<a type>, 'constant', 'enum', 'procedure', 'type' or 'function'"},
	{ 19, "'%s' has not been declared"},
	{ 20, "'%s' takes %s%d argument%s"},
	{ 21, "'$' must only appear between '[' and ']' or as the last item in a sequence literal."},
	{ 22, "a fallthru must be inside a switch"},
	{ 23, "A namespace qualifier is needed to resolve '%s'\nbecause '%s' is declared as a global/public symbol in:\n%s"},
	{ 24, "a variable name is expected here"},
	{ 25, "a name is expected here"},
	{ 26, "Argument %d of %s (%s) is defaulted, but has no default value"},
	{ 27, "An unknown 'with/without' option has been specified"},
	{ 28, "a loop variable name is expected here"},
	{ 29, "Argument %d is defaulted, but has no default value"},
	{ 30, "An enum constant must be an integer"},
	{ 31, "attempt to redefine %s."},
	{ 32, "an identifier is expected here"},
	{ 33, "a case block cannot follow a case else block"},
	{ 34, "a case must be inside a switch"},
	{ 35, "A label clause must be followed by a constant string"},
	{ 36, "a new namespace identifier is expected here"},
	{ 37, "a type is expected here"},
	{ 38, "A label clause must be followed by a literal string"},
	{ 39, "break must be inside an if block "},
	{ 40, "break statement must be inside a if or a switch block"},
	{ 41, "badly-formed list of parameters - expected ',' or ')'"},
	{ 42, "Block comment from line %d not terminated."},
	{ 43, "Compiler is unknown"},
	{ 44, "case else cannot be first case in switch"},
	{ 45, "Couldn't open %s%s for writing"},
	{ 46, "cannot build a dll for DOS"},
	{ 47, "Can't open main-.h file for output\n"},
	{ 48, "Cannot use the filename, %s, under DOS.\nUse the Windows version with -plat DOS instead.\n"},
	{ 49, "continue statement must be inside a loop"},
	{ 50, "continue must be inside a loop"},
	{ 51, "can't open '%s'"},
	{ 52, "can't find '%s' in any of ...\n%s"},
	{ 53, "Can't open init-.c for append\n"},
	{ 54, "Can't open main-.c for output\n"},
	{ 55, "Can't open init-.c for output\n"},
	{ 56, "character constant is missing a closing '"},
	{ 57, "Couldn't open .c file for output"},
	{ 58, "DJGPP option only available for DOS."},
	{ 59, "Duplicate label name"},
	{ 60, "DJGPP environment variable is not set"},
	{ 61, "defined word must only have alphanumerics and underscore"},
	{ 62, "digit '%s' at position %d is outside of number base"},
	{ 63, "duplicate case value used."},
	{ 64, "duplicate entry clause in a loop header"},
	{ 65, "End of file reached while searching for 'end ifdef' to match 'ifdef' on line %d"},
	{ 66, "expected 'then' or ',', not %s"},
	{ 67, `end of line reached with no closing "`},
	{ 68, "expected %s, not %s"},
	{ 69, "expected ',' or ')'"},
	{ 70, "enum constants must be assigned an integer"},
	{ 71, "expected an atom, string or a constant assigned an atom or a string"},
	{ 72, "entry must be inside a loop"},
	{ 73, "entry statement is being used without a corresponding entry clause in the loop header"},
	{ 74, "Errors resolving the following references:\n%s"},
	{ 75, "Expecting 'end ifdef' to match 'ifdef' on line %d"},
	{ 76, "expected to see an assignment after '%s', such as =, +=, -=, *=, /= or &="},
	{ 77, "Expecting 'then' on 'elsifdef' line"},
	{ 78, "Expecting a 'word' to follow 'elsifdef'"},
	{ 79, "Expected end of %s block, not %s"},
	{ 80, "entry keyword is not supported inside an if or switch block header"},
	{ 81, "Expecting to find a word to define but reached end of line first."},
	{ 82, "expecting possibly 'then' not end of line"},
	{ 83, "entry is not supported in for loops"},
	{ 84, "enum constants must be integers"},
	{ 85, "expected to see a parameter declaration, not ')'"},
	{ 86, "exponent not formed correctly"},
	{ 87, "exit/break argument out of range"},
	{ 88, "exit statement must be inside a loop"},
	{ 89, "exit must be inside a loop"},
	{ 90, "found %s '%s' but was expecting a parameter name instead."},
	{ 91, "found %s but expected 'else', an atom, string, constant or enum"},
	{ 92, "found %s but was expecting a parameter name instead."},
	{ 93, "Fast FP option only available for DOS"},
	{ 94, "fractional part of number is missing"},
	{ 95, "file name is missing"},
	{ 96, "Goto statement without a string label."},
	{ 97, "hex number not formed correctly"},
	{ 98, "internal nested call parsing error"},
	{ 99, "integer or constant expected"},
	{100, "improper syntax for include-as"},
	{101, "illegal character in source"},
	{102, "illegal character"},
	{103, "illegal character (ASCII 0) at line:col %d:%d"},
	{104, "includes are nested too deeply"},
	{105, "Invalid number base specifier '%s'"},
	{106, "internal: deref problem"},
	{107, "leaving too many blocks %d > %d"},
	{108, "Mismatched 'else'. Should this be an 'elsedef' to match 'ifdef' on line %d"},
	{109, "may not assign to a for-loop variable"},
	{110, "may not change the value of a constant"},
	{111, "Mismatched 'end if'. Should this be an 'end ifdef' to match 'ifdef' on line %d"},
	{112, "Multitasking operations are not supported in a .dll or .so"},
	{113, "missing namespace qualifier"},
	{114, "missing default namespace qualifier"},
	{115, "missing closing quote on file name"},
	{116, "Not expecting anything on same line as 'elsdef'"},
	{117, "Not expecting to see '%s' here"},
	{118, "Not expecting 'else'"},
	{119, "Not expecting 'elsif'"},
	{120, "no value returned from function"},
	{121, "number not formed correctly"},
	{122, "no 'word' was found following %s"},
	{123, "out of memory - turn off trace and profile"},
	{124, "only one decimal point allowed"},
	{125, "Only integer literals can use the '0%s' format"},
	{126, "program includes too many files"},
	{127, "Punctuation missing in between number and '%s'"},
	{128, "retry must be inside a loop"},
	{129, "Raw string literal from line %d not terminated."},
	{130, "return must be inside a procedure or function"},
	{131, "retry statement must be inside a loop"},
	{132, "Syntax error - expected to see possibly %s, not %s"},
	{133, "Syntax error - Unknown namespace '%s' used"},
	{134, "Should this be 'elsedef' for the ifdef on line %d?"},
	{135, "Syntax error - expected to see an expression, not %s"},
	{136, "sample size must be a positive integer"},
	{137, "single-quote character is empty"},
	{138, "Syntax error - expected to see %s after %s, not %s"},
	{139, "Should this be 'elsifdef' for the ifdef on line %d?"},
	{140, "Sorry, too many .c files with the same base name"},
	{141, "the entry statement must appear at most once inside a loop"},
	{142, "the entry statement can not be used in a 'for' block"},
	{143, "the innermost block containing an entry statement must be the loop it defines an entry in."},
	{144, "the entry statement must appear inside a loop"},
	{145, """tab character found in string - use \t instead"""},
	{146, "Type Check Error when inlining literal"},
	{147, "too many warning errors"},
	{148, "types must have exactly one parameter"},
	{149, "type must return true / false value"},
	{150, "Unknown compiler"},
	{151, "Unknown build file type"},
	{152, "Unknown block label"},
	{153, "Unknown namespace in replayed token"},
	{154, "unknown with/without option '%s'"},
	{155, "unknown escape character"},
	{156, "Unknown label '%s'"},
	{157, "Variable %s has not been declared"},
	{158, "Wrong number of arguments supplied for forward reference\n\t%s (%d): %s %s.  Expected %d, but found %d."},
	{159, "WATCOM environment variable is not set"},
	{160, "warning names must be enclosed in '(' ')'"},
	{161, "#! may only be on the first line of a program"},
	{162, "Writing emake file %s%s"},
	{163, "Compiling %2.0f%% %s"},
	{164, "Couldn't compile file '%s'"},
	{165, "Status: %d Command: %s"},
	{166, "Linking 100%% %s"},
	{167, "Unknown compiler type: %d"},
	{168, "Unable to link %s"},
	{169, "Status: %d Command: %s"},
	{170, "\n%d.c files were created."},
	{171, "To build your project, include %s.cmake into a parent CMake project"},
	{172, "To build your project, type %s%s.mak"},
	{173, "To build your project, include %s.mak into a larger Makefile project"},
	{174, "To build your project, type %s"},
	{175, "\nTo run your project, type %s"},
	{176, "Compiling with %s"},
	$
}

public function GetMsgText( integer MsgNum, integer WithNum = 1)
	integer idx = 1
	object lMsgText
	
	-- First check localization databases
	lMsgText = get_text( MsgNum, LocalizeQual, LocalDB )
	
	-- If not found, scan through hard-coded messages
	if atom(lMsgText) then
		for i = 1 to length(StdErrMsgs) do
			if StdErrMsgs[i][1] = MsgNum then
				idx = i
				exit
			end if
		end for
		lMsgText = StdErrMsgs[idx][2]
	end if
	
	if WithNum != 0 then
		return sprintf("[%04d]:: %s", {MsgNum, lMsgText})
	else
		return lMsgText
	end if
end function

public procedure ShowMsg(integer Cons, object Msg, object Args = {}, integer NL = 1)

	if atom(Msg) then
		Msg = GetMsgText(floor(Msg), 0)
	end if
	
	if atom(Args) or length(Args) != 0 then
		Msg = sprintf(Msg, Args)
	end if
	
	puts(Cons, Msg)
	
	if NL then
		puts(Cons, '\n')
	end if
	
end procedure
