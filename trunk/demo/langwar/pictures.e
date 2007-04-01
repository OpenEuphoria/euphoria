    -----------------------------------------
    -- Bitmap images for various objects --
    -----------------------------------------

--   16 color graphics modes:

--   BLACK   = 0         GRAY           = 8
--   BLUE    = 1         BRIGHT_BLUE    = 9
--   GREEN   = 2         BRIGHT_GREEN   = A
--   CYAN    = 3         BRIGHT_CYAN    = B
--   RED     = 4         BRIGHT_RED     = C
--   MAGENTA = 5         BRIGHT_MAGENTA = D
--   BROWN   = 6         YELLOW         = E
--   WHITE   = 7         BRIGHT_WHITE   = F

-- low order 4 bits determine the color seen by the user
-- 0: black part of outer space
-- 1..15: colored part of a solid object
-- 16..31: POD - solid, but phasors/torps can pass through it
-- 32: black part of a solid object
-- 33..64: torpedos/phasors/explosion colored bits 
--         - ignorable fluff with no effect on the game
-- 65...: stars - no effect on game, but they shouldn't be destroyed


function make_image(sequence digits)
-- convert a 2-d sequence of hex digits into a 2-d image
    integer c
    
    for i = 1 to length(digits) do
	for j = 1 to length(digits[i]) do
	    c = digits[i][j] 
	    if c = ' ' then
		c = 32 -- BLACK (transparent) part of an object
	    elsif c >= 'A' then
		c -= 'A' - 10
	    else
		c -= '0'
	    end if
	    digits[i][j] = c
	end for
    end for
    return digits
end function

function flip_image(sequence digits)
-- make left-right mirror image
    for i = 1 to length(digits) do
	digits[i] = reverse(digits[i])
    end for
    return digits
end function

global constant
    STAR1 = 64 + BRIGHT_WHITE,  -- bright star, greater than 64

    STAR2 = 64 + WHITE,   -- duller star, greater than 64
		       
    TORPEDO = make_image({"FF",  -- the dot used for torpedos and phasors
			  "FF"
			 })+32,
    TORPEDO_WIDTH = length(TORPEDO[1]),
    TORPEDO_HEIGHT = length(TORPEDO),
    
    POD = make_image({"F0000F",
		      "0FFFF0",
		      "FF00FF",
		      "0FFFF0",
		      "F0000F"
		     })+16,
    
    BASE = make_image({"          EEEEEEEE          ",
		       "          EEEEEEEE          ",
		       "             EE             ",
		       "             EE             ",
		       "             EE             ",
		       "             EE             ",
		       "        EEEEEEEEEEEE        ",
		       "       EEEEEEEEEEEEEE       ",
		       "      EEE    EE    EEE      ",
		       "EE    EEE    EE    EEE    EE",
		       "EE    EEE    EE    EEE    EE",
		       "EEEEEEEEEEEEEEEEEEEEEEEEEEEE",
		       "EEEEEEEEEEEEEEEEEEEEEEEEEEEE",
		       "EE    EEE    EE    EEE    EE",
		       "EE    EEE    EE    EEE    EE",
		       "      EEE    EE    EEE      ",
		       "       EEEEEEEEEEEEEE       ",
		       "        EEEEEEEEEEEE        ",
		       "             EE             ",
		       "             EE             ",
		       "             EE             ",
		       "             EE             ",
		       "          EEEEEEEE          ",
		       "          EEEEEEEE          "
		      }),
    
    PLANET  = make_image({
		     "                   6666666666                   ",
		     "                6666666666666666                ",
		     "              66666666666666666666              ",
		     "            666666666666666666666666            ",
		     "          6666666666666666666666666666          ",
		     "        66666666666666666666666666666666        ",
		     "       6666666666666666666666666666666666       ",
		     "      666666666666666666666666666666666666      ",
		     "     66666666666666666666666666666666666666     ",
		     "    6666666666666666666666666666666666666666    ",
		     "    6666666666666666666666666666666666666666    ",
		     "   666666666666666666666666666666666666666666   ",
		     "   666666666666666666666666666666666666666666   ",
		     "  66666666666666666666666666666666666666666666  ",
		     "  66666666666666666666666666666666666666666666  ",
		     "  66666666666666666666666666666666666666666666  ",
		     " 6666666666666666666666666666666666666666666666 ",
		     " 6666666666666666666666666666666666666666666666 ",
		     " 6666666666666666666666666666666666666666666666 ",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     "666666666666666666666666666666666666666666666666",
		     " 6666666666666666666666666666666666666666666666 ",
		     " 6666666666666666666666666666666666666666666666 ",
		     " 6666666666666666666666666666666666666666666666 ",
		     "  66666666666666666666666666666666666666666666  ",
		     "  66666666666666666666666666666666666666666666  ",
		     "  66666666666666666666666666666666666666666666  ",
		     "   666666666666666666666666666666666666666666   ",
		     "   666666666666666666666666666666666666666666   ",
		     "    6666666666666666666666666666666666666666    ",
		     "    6666666666666666666666666666666666666666    ",
		     "     66666666666666666666666666666666666666     ",
		     "      666666666666666666666666666666666666      ",
		     "       6666666666666666666666666666666666       ",
		     "        66666666666666666666666666666666        ",
		     "          6666666666666666666666666666          ",
		     "            666666666666666666666666            ",
		     "              66666666666666666666              ",
		     "                6666666666666666                ",
		     "                   6666666666                   "
		     }),
    
    BASIC_L = make_image({"            9 9  9 9   ",
			  "            9 9  9 9   ",
			  "           99999 9999  ",
			  "99999999999     9      ",
			  "           99999 9999  ",
			  "            9 9  9 9   ",
			  "            9 9  9 9   "
			   }),
    BASIC_R = flip_image(BASIC_L),
    
    SHUTTLE_L = make_image({"            EE",
			    "      EEEEEEE ",
			    "EEEEEEE     E ",
			    "      EEEEEEE ",
			    "            EE"
			   }),
    SHUTTLE_R = flip_image(SHUTTLE_L),
    
    EUPHORIA_L = make_image({
			    "       EEEEEEEEEE",
			    " EEEE    EE      ",
			    "EE  EE   E       ",
			    "E    EEEEEEE     ",
			    "EE  EE   E       ",
			    " EEEE    EE      ",
			    "       EEEEEEEEEE"
			  }),
    EUPHORIA_R = flip_image(EUPHORIA_L),

    -- Java when shooting
    JAVA_LS = make_image({
			 "                  AAA", 
			 "      AAAA       AA  ",
			 "    AACCCCAA    AAA  ",
			 "  AAACCCCCCAAAAAAAA  ",
			 "AAAAACCCCCCAAAAAAAAAA",
			 "  AAACCCCCCAAAAAAAA  ",
			 "    AACCCCAA    AAA  ",
			 "      AAAA       AA  ",
			 "                  AAA"
			}),   
    JAVA_RS = flip_image(JAVA_LS),   

    -- normal Java
    JAVA_L = make_image({
			 "                  AAA", 
			 "      AAAA       AA  ",
			 "    AA    AA    AAA  ",
			 "  AAA      AAAAAAAA  ",
			 "AAAAA      AAAAAAAAAA",
			 "  AAA      AAAAAAAA  ",
			 "    AA    AA    AAA  ",
			 "      AAAA       AA  ",
			 "                  AAA"
			}),   
    JAVA_R = flip_image(JAVA_L),   

    KRC_L = make_image({
			"              CC       ",
			"             CC        ",
			"            CC         ",
			"    CC     CC        CC",
			"   C  C    CC      CC  ",
			"   C  CCCCCCCCCCCCC    ",
			"CCCC  CCCCCCCCCCCCC    ",
			"   C  CCCCCCCCCCCCC    ",
			"   C  C    CC      CC  ",
			"    CC     CC        CC",
			"            CC         ",
			"             CC        ",
			"              CC       "
			}),   
    KRC_R = flip_image(KRC_L),   
    
    ANC_L = make_image({
			"                    CC        ",
			"                   CC         ",
			"                  CC          ",
			"       CCC       CCC       CCC",
			"     CC   CC    CCCC     CCC  ",
			"   CCC     CCCCCCCCCCCCCCCC   ",
			"CCCCC      CCCCCCCCCCCCCCCCCCC",
			"   CCC     CCCCCCCCCCCCCCCC   ",
			"     CC   CC    CCCC     CCC  ",
			"       CCC       CCC       CCC",
			"                  CC          ",
			"                   CC         ",
			"                    CC        "
			}),   
    ANC_R = flip_image(ANC_L),   
    
    -- =8**<",
    CPP_L = make_image({
			"                    DDDDDD    ",
			"                   DDDDD      ",
			"                  DDDDD       ",
			"                 DDDDD        ",
			"       DD       DDDD       DDD",
			"DDDDDDD  DD    DDDD       DD  ",
			"DDDDDD    DDDDDDDDDDDDDDDDD   ",
			"     D    DDDDDDDDDDDDDDDD    ",
			"     D    DDDDDDDDDDDDDDDDDDDD",
			"     D    DDDDDDDDDDDDDDDD    ",
			"DDDDDD    DDDDDDDDDDDDDDDDD   ",
			"DDDDDDD  DD    DDDD       DD  ",
			"       DD       DDDD       DDD",
			"                 DDDDD        ",
			"                  DDDDD       ",
			"                   DDDDD      ",
			"                    DDDDDD    "
			}),   
    CPP_R = flip_image(CPP_L)

font_index[1+'@'] = {  -- cross shape in direction box
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {1,1,1,1,1,1,1,1},
	    {1,1,1,1,1,1,1,1},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0}}

global constant TORP_SYM = 250,
		DEFL_SYM = 251,
		 POD_SYM = 252

font_index[1+TORP_SYM] = {  -- torpedo symbol on console
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,1,1,1,1,0,0},
	    {0,1,1,1,1,1,1,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,1,1,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0}}

font_index[1+DEFL_SYM] = {  -- deflector symbol on console
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,1,1,1,1,1,0,0},
	    {1,1,1,1,1,1,1,0},
	    {1,1,0,0,0,1,1,0},
	    {1,0,0,0,0,0,1,0},
	    {1,0,0,0,0,0,1,0},
	    {1,0,0,0,0,0,1,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0}}

font_index[1+POD_SYM] = {  -- POD symbol on console
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {1,1,0,0,0,0,1,1},
	    {0,0,1,1,1,1,0,0},
	    {0,0,1,1,1,1,0,0},
	    {0,1,1,0,0,1,1,0},
	    {0,1,1,0,0,1,1,0},
	    {0,0,1,1,1,1,0,0},
	    {0,0,1,1,1,1,0,0},
	    {1,1,0,0,0,0,1,1},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0},
	    {0,0,0,0,0,0,0,0}}
	    
