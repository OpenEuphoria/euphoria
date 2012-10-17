include std/ucstypes.e
include std/unittest.e

constant BABY = #1F476, ENYEA = #00D1, enyea = #F1, ESpANa = "EspA" & ENYEA & 'a', espana = "espa" & enyea & 'a', GREGORIAN_PAR = #2D0E, gregorian_par = #2D0E
test_equal("lower:GEORGIAN CAPITAL LETTER PAR", #2D0E, lower(#10AE))
test_equal("lower:LATIN CAPITAL A", 'a', lower('A'))
test_equal("lower:LATIN SMALL A", 'a', lower('a'))
test_equal("lower:COPTIC SMALL LETTER DEI => itself", #03EF, lower(#03EF))
test_equal("lower:LATIN CAPITAL LETTER T WITH CEDILLA", #0163, lower(#0162))
test_equal("lower:ESpaNa WITH TILDE => espana with tilde", "espa" & #00F1 & "a", lower("ESpA" & #00D1 & "a"))
test_equal("lower:GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI",#1F80,lower(#1F88))
test_equal("lower:BABY => BABY", BABY, lower(BABY))
test_report()
