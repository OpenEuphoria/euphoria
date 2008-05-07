without warning -- rid ourselves of the redefined built-in match warning

-- TODO:
--
-- * Support the parameter to exec_pcre for start offset and create a 
--   match_from function
-- * Change the regex type to a sequence, and optionally support the ability
--   to study a regular expression. The result of the study can be placed
--   into element #2 of regex sequence
-- * Why does exec_pcre not return all matches? It should?
-- * Create a replace function that will match/replace.
-- * Create an advanced match/replace function that will call a user routine
--   passing the match, in which it returns the replacement text
-- * Wrap pcre_free
-- * Define many flags that can be sent to exec_pcre as constants
-- * Make exec_pcre support those flags
--

constant
    M_COMPILE_PCRE = 68,
    M_EXEC_PCRE = 69

global type regex(object o)
    return atom(o)
end type

-- TODO: document, test
global function new(sequence pattern)
    return machine_func(M_COMPILE_PCRE, pattern)
end function

-- TODO: document, test
global function match(regex re, sequence s)
    return machine_func(M_EXEC_PCRE, {re, s})
end function

