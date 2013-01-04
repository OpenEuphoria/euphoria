--****
-- == Hashing Algorithms
--
-- <<LEVELTOC level=2 depth=4>>
--
namespace stdhash

--****
-- === Type Constants
--

public enum
	HSIEH30 = -6,
	HSIEH32,
	ADLER32,
	FLETCHER32,
	MD5,
	SHA256

--****
-- === Routines
--

--****
-- Signature:
--   <built-in> function hash(object source, atom algo)
--
-- Description:
--     calculates a hash value for a //key// using the algorithm ##algo##.
--
-- Parameters:
--		# ##source## : Any Euphoria object
--		# ##algo## : A code indicating which algorithm to use.
-- ** ##HSIEH30## uses Hsieh. Returns a 30-bit (a Euphoria integer). Fast and good dispersion
-- ** ##HSIEH32## uses Hsieh. Returns a 32-bit value. Fast and very good dispersion
-- ** ##ADLER32## uses Adler. Very fast and reasonable dispersion, especially for small strings
-- ** ##FLETCHER32## uses Fletcher. Very fast and good dispersion
-- ** ##MD5## uses MD5 (not implemented yet) Slower but very good dispersion. 
--            Suitable for signatures.
-- ** ##SHA256## uses SHA256 (not implemented yet) Slow but excellent dispersion. 
--            Suitable for signatures. More secure than MD5.
-- ** 0 and above (integers and decimals) and non-integers less than zero use
--          the cyclic variant ##(hash = hash * algo + c)##.
--          This is a fast and good to excellent
--          dispersion depending on the value of //algo//. Decimals give better
--          dispersion but are slightly slower.
--
-- Returns:
--     An **atom**,
--        Except for the ##HSIEH30##, ##MD5## and ##SHA256## algorithms, this is a 32-bit integer.\\
--     An **integer**,
--        Except for the ##HSIEH30## algorithms, this is a 30-bit integer.\\
--     A **sequence**,
--        ##MD5## returns a 4-element sequence of integers\\
--        ##SHA256## returns a 8-element sequence of integers.
--
-- Comments:
-- * For ##algo## values from zero to less than one, that actual value used is ##(algo + 69096)##. 
--
-- Example 1:
-- <eucode>
-- ? hash("The quick brown fox jumps over the lazy dog", 0         ) --> 3071488335
-- ? hash("The quick brown fox jumps over the lazy dog", 99        ) --> 4122557553
-- ? hash("The quick brown fox jumps over the lazy dog", 99.94     ) -->   95918096
-- ? hash("The quick brown fox jumps over the lazy dog", -99.94    ) --> 4175585990
-- ? hash("The quick brown fox jumps over the lazy dog", HSIEH30   ) -->   96435427
-- ? hash("The quick brown fox jumps over the lazy dog", HSIEH32   ) -->   96435427
-- ? hash("The quick brown fox jumps over the lazy dog", ADLER32   ) --> 1541148634
-- ? hash("The quick brown fox jumps over the lazy dog", FLETCHER32) --> 1730140417
-- ? hash(123,                                           99        ) --> 1188623852
-- ? hash(1.23,                                          99        ) --> 3808916725
-- ? hash({1, {2,3, {4,5,6}, 7}, 8.9},                   99        ) -->  526266621
-- </eucode>
