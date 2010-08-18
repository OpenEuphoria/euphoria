-- vars.e
-- declarations of public variables and constants

public constant TRUE = 1, FALSE = 0

public constant BS = 8  -- backspace key

public constant G_SIZE = 7 -- the galaxy is a G_SIZE x G_SIZE
               -- grid of quadrants

public constant INVISIBLE_CHAR = 32 -- prints as ' ', but has different value

public constant TICK_RATE = 100

public type boolean(integer x)
    return x = TRUE or x = FALSE
end type

public type char(integer c)
-- true if c is a character that can be printed on the screen
    return c >= 0 and c <= 127
end type

public type natural(integer x)
    return x >= 0
end type

public type positive_int(integer x)
    return x >= 1
end type

public type positive_atom(atom x)
    return x >= 0
end type

include screen.e

-- static tasks, always present
-- additional tasks are created dynamically
public integer t_keyb,    -- keyboard input
           t_emove,   -- Euphoria move
           t_docking, -- docking display
           t_life,    -- life support energy consumption
           t_dead,    -- dead body cleanup
           t_bstat,   -- BASIC status change
           t_fire,    -- enemy firing
           t_move,    -- enemy moving
           t_message, -- display messages
           t_damage_report,  -- damage count-down
           t_enter,   -- enemy ships enter quadrant
           t_sound_effect,   -- sound effects
           t_gquad,   -- refresh current quadrant on scan
           t_video_snapshot, -- record snapshot of screen
           t_video_save  -- save video to disk

-----------------------------------------------------------------------------
-- the 2-d quadrant sequence: status of all objects in the current quadrant
-- The first object is always the Euphoria. There will be 0 or more
-- additional objects (planets/bases/enemy ships).
-----------------------------------------------------------------------------
public constant EUPHORIA = 1    -- object 1 is Euphoria

public constant
    Q_TYPE =   1, -- type of object
    Q_EN   =   2, -- energy
    Q_TORP =   3, -- number of torpedos
    Q_DEFL =   4, -- number of deflectors
    Q_FRATE =  5, -- firing rate
    Q_MRATE =  6, -- moving rate
    Q_TARG =   7, -- target
    Q_PBX =    8, -- planet/base sequence index
    Q_X =      9, -- x coordinate
    Q_Y =     10, -- y coordinate
    Q_UNDER = 11, -- characters underneath
    Q_DIRECTION = 12 -- direction enemy ship moved in last time
public constant QCOLS = 12 -- number of attributes for each object in quadrant

public sequence quadrant
quadrant = repeat(repeat(0, QCOLS), 1)

public type task(integer x)
-- is x a valid task id?
    return x >= 0
end type

public type h_coord(integer x)
-- true if x is a horizontal screen coordinate
    return x >= 1 and x <= HSIZE
end type

public type v_coord(integer y)
-- true if y is a vertical screen coordinate
    return y >= 1 and y <= VSIZE
end type

public type extended_h_coord(atom x)
    -- horizontal coordinate, can be reasonably far off the screen
    return x >= -1000 and x <= HSIZE + 1000
end type

public type extended_v_coord(atom y)
    -- vertical coordinate, can be reasonably far off the screen
    return y >= -1000 and y <= VSIZE + 1000
end type

public type image(sequence s)
-- a 2-d rectangular image
    return sequence(s[1])
end type

public type valid_quadrant_row(integer x)
-- true if x is a valid row number in the quadrant sequence
    return x >= 1 and x <= length(quadrant)
end type

public type quadrant_row(object x)
-- either a quadrant row or -1 or 0 (null value)
    return valid_quadrant_row(x) or x = -1 or x = 0
end type

-----------------------------------------------------------------------------
-- the 3-d galaxy sequence: (records number of objects of each type in
--                           each quadrant of the galaxy)
-----------------------------------------------------------------------------
-- first two subscripts select quadrant, 3rd is type...

public constant DEAD = 0 -- object that has been destroyed
public constant
    G_EU = 1,   -- Euphoria (marks if Euphoria has been in this quadrant)
    G_KRC = 2,  -- K&R C ship
    G_ANC = 3,  -- ANSI C ship
    G_CPP = 4,  -- C++
    G_BAS = 5,  -- basic
    G_JAV = 6,  -- Java
    G_PL = 7,   -- planet
    G_BS = 8,   -- base
    NTYPES = 8, -- number of different types of (real) object
    G_POD = 9   -- temporary pseudo object

public sequence otype

public type object_type(integer x)
-- is x a type of object?
    return x >= 1 and x <= NTYPES
end type

public sequence galaxy

-----------------------------------------------------------------------------
-- the planet/base 2-d sequence (info on each planet and base in the galaxy)
-----------------------------------------------------------------------------
public constant NBASES = 3,  -- number of bases
        NPLANETS = 6 -- number of planets
public constant
    PROWS = NBASES+NPLANETS,
    PCOLS = 9     -- number of planet/base attributes
public constant
    P_TYPE  = 1, -- G_PL/G_BS/DEAD
    P_QR    = 2, -- quadrant row
    P_QC    = 3, -- quadrant column
    P_X     = 4, -- x coordinate within quadrant
    P_Y     = 5, -- y coordinate within quadrant
    P_EN    = 6, -- energy available
    P_TORP  = 7, -- torpedos available
    P_POD   = 8  -- pods available

public sequence pb
pb = repeat(repeat(0, PCOLS), PROWS)

public type pb_row(integer x)
-- is x a valid row in the planet/base sequence?
    return x >= 1 and x <= PROWS
end type

public type g_index(integer x)
-- a valid row or column index into the galaxy sequence
    return x >= 1 and x <= G_SIZE
end type

public g_index qrow, qcol  -- current quadrant row and column

------------------
-- BASIC status:
------------------
public constant
    TRUCE    = 0,
    HOSTILE  = 1,
    CLOAKING = 2

type basic_status(object x)
    return find(x, {TRUCE, HOSTILE, CLOAKING})
end type

public basic_status bstat       -- BASIC status
public quadrant_row basic_targ  -- BASIC group target
public boolean truce_broken     -- was the truce with the BASICs broken?

public boolean shuttle -- are we in the shuttle?

-----------------
-- damage report:
-----------------
public constant NSYS = 5  -- number of systems that can be damaged
public constant ENGINES        = 1,
        TORPEDOS       = 2,
        GUIDANCE       = 3,
        PHASORS        = 4,
        GALAXY_SENSORS = 5

public constant dtype = {"ENGINES",
             "TORPEDO LAUNCHER",
             "GUIDANCE SYSTEM",
             "PHASORS",
             "SENSORS"}
public type subsystem(integer x)
    return x >= 1 and x <= NSYS
end type

public sequence reptime  -- time to repair a subsystem
reptime = repeat(0, NSYS)

type damage_count(integer x)
    return x >= 0 and x <= NSYS
end type

public damage_count ndmg

--------------
-- warp speed:
--------------
public constant MAX_WARP = 5

public type warp(integer x)
    return x >= 0 and x <= MAX_WARP
end type

public warp curwarp, wlimit

public type direction(atom x)
    return x >= 0 and x < 10
end type

public direction curdir -- current Euphoria direction

-------------------------------------
-- Euphoria position and direction:
-------------------------------------
type euphoria_x_inc(integer x)
    return x >= -1 and x <= +1
end type

type euphoria_y_inc(integer x)
    return x >= -1 and x <= +1
end type

public euphoria_x_inc exi
public euphoria_y_inc eyi

public sequence esym,   -- euphoria/shuttle symbol
        esyml,  -- euphoria/shuttle facing left
        esymr   -- euphoria/shuttle facing right

public sequence nobj  -- number of each type of object in galaxy

public sequence wipeout
wipeout = {}

type game_level(integer x)
    return x = 'n' or x = 'e'
end type

public game_level level

public procedure ftrace(sequence msg)
  integer fh

  fh = open("ftrace.txt", "a")
  puts(fh, msg)
  puts(fh, "\n")
  close(fh)
end procedure
