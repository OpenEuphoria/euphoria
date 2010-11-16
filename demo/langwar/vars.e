-- vars.e
-- declarations of global variables and constants

global constant TRUE = 1, FALSE = 0

global constant CRT = 1 -- output device

global constant G_SIZE = 7 -- the galaxy is a G_SIZE x G_SIZE
			   -- grid of quadrants

global constant INVISIBLE_CHAR = ' ' + 256 -- prints as ' '
					   -- but has different value

global type boolean(integer x)
    return x = TRUE or x = FALSE
end type

global type char(integer c)
-- true if c is a character that can be printed on the screen
    return c >= ' ' and c <= 127 or c = INVISIBLE_CHAR
end type

global type byte(integer x)
    return x >= -1 and x <= 255
end type

global type natural(integer x)
    return x >= 0
end type

global type positive_atom(atom x)
    return x >= 0
end type

-----------------------------------------------------------------------------
-- the 2-d quadrant sequence: status of all objects in the current quadrant
-- The first object is always the Euphoria. There will be 0 or more
-- additional objects (planets/bases/enemy ships).
-----------------------------------------------------------------------------
global constant EUPHORIA = 1    -- object 1 is Euphoria

global constant QCOLS = 12 -- number of attributes for each object in quadrant
global constant
    Q_TYPE =   1, -- type of object
    Q_EN   =   2, -- energy
    Q_TORP =   3, -- number of torpedos
    Q_DEFL =   4, -- number of deflectors
    Q_FRATE =  5, -- firing rate
    Q_MRATE =  6, -- moving rate
    Q_TARG =   7, -- target
    Q_DOCK =   8, -- docked yet?
    Q_PBX =    9, -- planet/base sequence index
    Q_X =     10, -- x coordinate
    Q_Y =     11, -- y coordinate
    Q_UNDER = 12  -- characters underneath

global sequence quadrant
quadrant = repeat(repeat(0, QCOLS), 1)

global type valid_quadrant_row(integer x)
-- true if x is a valid row number in the quadrant sequence
    return x >= 1 and x <= length(quadrant)
end type

global type quadrant_row(object x)
-- either a quadrant row or -1 or 0 (null value)
    return valid_quadrant_row(x) or x = -1 or x = 0
end type

-----------------------------------------------------------------------------
-- the 3-d galaxy sequence: (records number of objects of each type in
--                           each quadrant of the galaxy)
-----------------------------------------------------------------------------
-- first two subscripts select quadrant, 3rd is type...

global constant DEAD = 0 -- object that has been destroyed
global constant
    G_EU = 1,   -- Euphoria (marks if Euphoria has been this quadrant)
    G_KRC = 2,  -- K&R C ship
    G_ANC = 3,  -- ANSI C ship
    G_CPP = 4,  -- C++
    G_BAS = 5,  -- basic
    G_JAV = 6,  -- Java
    G_PL = 7,   -- planet
    G_BS = 8,   -- base
    NTYPES = 8, -- number of different types of (real) object
    G_POD = 9   -- temporary pseudo object

global sequence otype

global type object_type(integer x)
-- is x a type of object?
    return x >= 1 and x <= NTYPES
end type

global sequence galaxy

-----------------------------------------------------------------------------
-- the planet/base 2-d sequence (info on each planet and base in the galaxy)
-----------------------------------------------------------------------------
global constant NBASES = 3,  -- number of bases
		NPLANETS = 6 -- number of planets
global constant
    PROWS = NBASES+NPLANETS,
    PCOLS = 9     -- number of planet/base attributes
global constant
    P_TYPE  = 1, -- G_PL/G_BS/DEAD
    P_QR    = 2, -- quadrant row
    P_QC    = 3, -- quadrant column
    P_X     = 4, -- x coordinate within quadrant
    P_Y     = 5, -- y coordinate within quadrant
    P_EN    = 6, -- energy available
    P_TORP  = 7, -- torpedos available
    P_POD   = 8  -- pods available

global sequence pb
pb = repeat(repeat(0, PCOLS), PROWS)

global type pb_row(integer x)
-- is x a valid row in the planet/base sequence?
    return x >= 1 and x <= PROWS
end type

global type g_index(integer x)
-- a valid row or column index into the galaxy sequence
    return x >= 1 and x <= G_SIZE
end type

global boolean gameover  -- is game over?

global g_index qrow, qcol  -- current quadrant row and column

------------------
-- BASIC status:
------------------
global constant
    TRUCE    = 0,
    HOSTILE  = 1,
    CLOAKING = 2

type basic_status(object x)
    return find(x, {TRUCE, HOSTILE, CLOAKING})
end type

global basic_status bstat       -- BASIC status
global quadrant_row basic_targ  -- BASIC group target
global boolean truce_broken     -- was the truce with the BASICs broken?

global boolean shuttle -- are we in the shuttle?

----------------------------------------------
-- multiple tasks
-- This game has 10 independent tasks running
----------------------------------------------
global constant NTASKS = 10 -- number of independent tasks

global constant
    TASK_KEYB     = 1, -- keyboard input
    TASK_EMOVE    = 2, -- Euphoria move
    TASK_LIFE     = 3, -- life support energy consumption
    TASK_DEAD     = 4, -- dead body cleanup
    TASK_BSTAT    = 5, -- BASIC status change
    TASK_FIRE     = 6, -- enemy firing
    TASK_MOVE     = 7, -- enemy moving
    TASK_MESSAGE  = 8, -- display messages
    TASK_DAMAGE   = 9, -- damage count-down
    TASK_ENTER    = 10 -- enemy ships enter quadrant

global type task(integer x)
-- is x a valid task number?
    return x >= 1 and x <= NTASKS
end type

global task current_task -- current task executing
global sequence tcb      -- task activation times
global sequence eat      -- early activation tolerance
global sequence wait     -- waiting time, in seconds, between activations

-----------------
-- damage report:
-----------------
global constant NSYS = 5  -- number of systems that can be damaged
global constant ENGINES        = 1,
		TORPEDOS       = 2,
		GUIDANCE       = 3,
		PHASORS        = 4,
		GALAXY_SENSORS = 5

global constant dtype = {"ENGINES",
			 "TORPEDO LAUNCHER",
			 "GUIDANCE SYSTEM",
			 "PHASORS",
			 "SENSORS"}
global type subsystem(integer x)
    return x >= 1 and x <= NSYS
end type

global sequence reptime  -- time to repair a subsystem
reptime = repeat(0, NSYS)

type damage_count(integer x)
    return x >= 0 and x <= NSYS
end type

global damage_count ndmg

--------------
-- warp speed:
--------------
global constant MAX_WARP = 5

global type warp(integer x)
    return x >= 0 and x <= MAX_WARP
end type

global warp curwarp, wlimit

global type direction(atom x)
    return x >= 0 and x < 10
end type

global direction curdir -- current direction

--------------------------------------
-- Graphic symbols for some objects --
--------------------------------------
global constant
    STAR = '.',
    TORPEDO = '*',
    POD = '@',
    DEFLECTOR = 'D',
    BASE = "<>-<>",         -- both halves
    PLANET_TOP    = INVISIBLE_CHAR & "OOOO" & INVISIBLE_CHAR,
    PLANET_MIDDLE = "OOOOOO",
    PLANET_BOTTOM = INVISIBLE_CHAR & "OOOO" & INVISIBLE_CHAR,
    BASIC_L = "-=##:",
    BASIC_R = ":##=-",
    SHUTTLE_L = "-=:",
    SHUTTLE_R = ":=-",
    EUPHORIA_L = "O-=",
    EUPHORIA_R = "=-O",
    JAVA_L = "-+<",
    JAVA_R = ">+-",
    KRC_L = "O**<",
    KRC_R = ">**O",
    ANC_L = "-8**<",
    ANC_R = ">**8-",
    CPP_L = "=8**<",
    CPP_R = ">**8="

global constant MAX_SHIP_WIDTH = 5 -- widest flying ship width

-------------------------------------
-- Euphoria position and direction:
-------------------------------------
type euphoria_x_inc(integer x)
    return x >= -3 and x <= +3
end type

type euphoria_y_inc(integer x)
    return x >= -1 and x <= +1
end type

global euphoria_x_inc exi
global euphoria_y_inc eyi

global sequence esym,   -- euphoria/shuttle symbol
		esyml,  -- euphoria/shuttle facing left
		esymr   -- euphoria/shuttle facing right

global sequence nobj  -- number of each type of object in galaxy

global positive_atom dist
global valid_quadrant_row shooter
global quadrant_row victim

global sequence wipeout
wipeout = {}

type game_level(integer x)
    return x = 'n' or x = 'e'
end type
global game_level level

