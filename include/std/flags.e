--****
-- == Flags
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace flags

include std/map.e

object one_bit_numbers = map:new()

map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0000_0001, 1)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0000_0010, 2)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0000_0100, 3)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0000_1000, 4)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0001_0000, 5)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0010_0000, 6)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_0100_0000, 7)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0000_1000_0000, 8)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0001_0000_0000, 9)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0010_0000_0000, 10)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_0100_0000_0000, 11)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0000_1000_0000_0000, 12)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0001_0000_0000_0000, 13)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0010_0000_0000_0000, 14)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_0100_0000_0000_0000, 15)
map:put(one_bit_numbers, 0b0000_0000_0000_0000_1000_0000_0000_0000, 16)
map:put(one_bit_numbers, 0b0000_0000_0000_0001_0000_0000_0000_0000, 17)
map:put(one_bit_numbers, 0b0000_0000_0000_0010_0000_0000_0000_0000, 18)
map:put(one_bit_numbers, 0b0000_0000_0000_0100_0000_0000_0000_0000, 19)
map:put(one_bit_numbers, 0b0000_0000_0000_1000_0000_0000_0000_0000, 20)
map:put(one_bit_numbers, 0b0000_0000_0001_0000_0000_0000_0000_0000, 21)
map:put(one_bit_numbers, 0b0000_0000_0010_0000_0000_0000_0000_0000, 22)
map:put(one_bit_numbers, 0b0000_0000_0100_0000_0000_0000_0000_0000, 23)
map:put(one_bit_numbers, 0b0000_0000_1000_0000_0000_0000_0000_0000, 24)
map:put(one_bit_numbers, 0b0000_0001_0000_0000_0000_0000_0000_0000, 25)
map:put(one_bit_numbers, 0b0000_0010_0000_0000_0000_0000_0000_0000, 26)
map:put(one_bit_numbers, 0b0000_0100_0000_0000_0000_0000_0000_0000, 27)
map:put(one_bit_numbers, 0b0000_1000_0000_0000_0000_0000_0000_0000, 28)
map:put(one_bit_numbers, 0b0001_0000_0000_0000_0000_0000_0000_0000, 29)
map:put(one_bit_numbers, 0b0010_0000_0000_0000_0000_0000_0000_0000, 30)
map:put(one_bit_numbers, 0b0100_0000_0000_0000_0000_0000_0000_0000, 31)
map:put(one_bit_numbers, 0b1000_0000_0000_0000_0000_0000_0000_0000, 32)

--****
-- === Routines
--

--**
-- tests if the supplied value has only a single bit on in its representation.
-- Parameters:
-- # ##theValue## : an object to test.
--
-- Returns:
-- An **integer**, either 0 if it contains multiple bits, zero bits or is an invalid value,
-- otherwise the bit number set. The right-most bit is position 1 and the leftmost bit
-- is position 32.
--
-- Example 1:
-- <eucode>
-- ? which_bit(2) --> 2
-- ? which_bit(0) --> 0
-- ? which_bit(3) --> 0
-- ? which_bit(4)          --> 3
-- ? which_bit(17)         --> 0
-- ? which_bit(1.7)        --> 0
-- ? which_bit(-2)         --> 0
-- ? which_bit("one")      --> 0
-- ? which_bit(0x80000000) --> 32
-- </eucode>

public function which_bit( object theValue )
	return map:get(one_bit_numbers, theValue, 0)
end function

--**
-- returns a list of strings that represent the human-readable identities of
-- the supplied flag or flags.
--
-- Parameters:
-- # ##flag_bits## : Either a single 32-bit set of flags (a flag value),
-- or a list of such flag values. The function returns the names for these flag values.
-- # ##flag_names## : A sequence of two-element sub-sequences. Each sub-sequence
-- is contains ##{FlagValue, FlagName}##, where //FlagName// is a string and 
-- //FlagValue// is the set of bits that set the flag on.
-- # ##expand_flags##: An integer. 0 (the default) means that the flag values in
-- ##flag_bits## are not broken down to their single-bit values. For example: ###0c## returns
-- the name of ###0c## and not the names for ###08## and ###04##. When ##expand_flags## is
-- non-zero then each bit in the ##flag_bits## parameter is scanned for a
-- matching name.
--
-- Returns:
-- A sequence. This contains the name or names for each supplied flag value or values.
--
-- Comments:
-- * The number of strings in the returned value depends on ##expand_flags## is 
-- non-zero and whether ##flags_bits## is an atom or sequence. 
-- * When ##flag_bits## is an atom, you get returned a sequence of strings, one
-- for each matching name (according to ##expand_flags## option). 
-- * When ##flag_bits## is a sequence, it is assumed to represent a list of
-- atomic flags. That is, ##{#1, #4}## is a set of two flags for which you want their
-- names. In this case, you get returned a sequence that contains one sequence
-- for each element in ##flag_bits##, which in turn contain the matching name or names.
-- * When a flag's name can not be found in ##flag_names##, this function returns
-- the //name// of "##?##".
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- sequence s
-- s = {
-- 	{#00000000, "WS_OVERLAPPED"},
-- 	{#80000000, "WS_POPUP"},
-- 	{#40000000, "WS_CHILD"},
-- 	{#20000000, "WS_MINIMIZE"},
-- 	{#10000000, "WS_VISIBLE"},
-- 	{#08000000, "WS_DISABLED"},
-- 	{#44000000, "WS_CLIPPINGCHILD"},
-- 	{#04000000, "WS_CLIPSIBLINGS"},
-- 	{#02000000, "WS_CLIPCHILDREN"},
-- 	{#01000000, "WS_MAXIMIZE"},
-- 	{#00C00000, "WS_CAPTION"},
-- 	{#00800000, "WS_BORDER"},
-- 	{#00400000, "WS_DLGFRAME"},
-- 	{#00100000, "WS_HSCROLL"},
-- 	{#00200000, "WS_VSCROLL"},
-- 	{#00080000, "WS_SYSMENU"},
-- 	{#00040000, "WS_THICKFRAME"},
-- 	{#00020000, "WS_MINIMIZEBOX"},
-- 	{#00010000, "WS_MAXIMIZEBOX"},
-- 	{#00300000, "WS_SCROLLBARS"},
-- 	{#00CF0000, "WS_OVERLAPPEDWINDOW"},
-- 	$
-- }
-- display( flags_to_string( {#0C20000,2,9,0}, s,1))
-- --> {
-- -->     "WS_BORDER",
-- -->     "WS_DLGFRAME",
-- -->     "WS_MINIMIZEBOX"
-- -->   },
-- -->   {
-- -->     "?"
-- -->   },
-- -->   {
-- -->     "?"
-- -->   },
-- -->   {
-- -->     "WS_OVERLAPPED"
-- -->   }
-- --> }
-- display( flags_to_string( #80000000, s))
-- --> {
-- -->   "WS_POPUP"
-- --> }
-- display( flags_to_string( #00C00000, s))
-- --> {
-- -->   "WS_CAPTION"
-- --> }
-- display( flags_to_string( #44000000, s))
-- --> {
-- -->   "WS_CLIPPINGCHILD"
-- --> }
-- display( flags_to_string( #44000000, s, 1))
-- --> {
-- -->   "WS_CHILD",
-- -->   "WS_CLIPSIBLINGS"
-- --> }
-- display( flags_to_string( #00000000, s))
-- --> {
-- -->   "WS_OVERLAPPED"
-- --> }
-- display( flags_to_string( #00CF0000, s))
-- --> {
-- -->   "WS_OVERLAPPEDWINDOW"
-- --> }
-- display( flags_to_string( #00CF0000, s, 1))
-- --> {
-- -->   "WS_BORDER",
-- -->   "WS_DLGFRAME",
-- -->   "WS_SYSMENU",
-- -->   "WS_THICKFRAME",
-- -->   "WS_MINIMIZEBOX",
-- -->   "WS_MAXIMIZEBOX"
-- --> }
-- </eucode>

public function flags_to_string(object flag_bits, sequence flag_names, integer expand_flags = 0 )
	-- s is a sequence of strings
    sequence s = {}
    if sequence(flag_bits) then
    	-- We have a list of flag values.
		for i = 1 to length(flag_bits) do
			-- N.B. Only one level of nesting is allowed.
			if not sequence(flag_bits[i]) then
				-- call recursively.
				flag_bits[i] = flags_to_string(flag_bits[i], flag_names, expand_flags)
			else
				-- By definition, this cannot be a flag value.
				flag_bits[i] = {"?"}
			end if
		end for
		s = flag_bits
	else
		integer has_one_bit
		
		-- See how many bits are set in this flag.
		has_one_bit = which_bit(flag_bits)
		for i = 1 to length(flag_names) do
			-- cache entry for performance.
			atom current_flag = flag_names[i][1]
			
			if flag_bits = 0 then
				-- Special case: no bits are set on therefore we must
				-- have an exact equality match.
				if current_flag = 0 then
					s = append(s,flag_names[i][2])
					exit
				end if
			elsif has_one_bit then
				-- Only one bit is set, so do a simple equality test.
				if current_flag = flag_bits then
					s = append(s,flag_names[i][2])
					exit
				end if
			elsif not expand_flags then
				-- We are not expanding the bits, so only need a simple equality test.
				if current_flag = flag_bits then
					s = append(s,flag_names[i][2])
					exit
				end if
			else
				-- Only look at entries that have a single bit set.
				if which_bit(current_flag) then
					-- Now see if the parameter has the same bit set.
					if and_bits( current_flag, flag_bits ) = current_flag then
						s = append(s,flag_names[i][2])
					end if
				end if
			end if
		end for
    end if
    
    -- If we didn't find anything, show that.
    if length(s) = 0 then
		s = append(s,"?")
    end if

    return s
end function
