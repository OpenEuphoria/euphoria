-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Mouse Routines

-- DOS32 - you need a mouse driver
-- Linux - you need GPM server to be running
-- WIN32 - not implemented yet for the text console

include misc.e

-- Mouse Events:
global integer MOVE, LEFT_DOWN, LEFT_UP, RIGHT_DOWN, RIGHT_UP,
	       MIDDLE_DOWN, MIDDLE_UP, ANY_UP

if platform() = LINUX then
    MOVE = 0
    LEFT_DOWN = 4
    LEFT_UP = 4
    RIGHT_DOWN = 1
    RIGHT_UP = 1
    MIDDLE_DOWN = 2
    MIDDLE_UP = 2
    ANY_UP = 35  -- LEFT, RIGHT or MIDDLE up (best you can do under xterm)
else
    MOVE = 1
    LEFT_DOWN = 2
    LEFT_UP = 4
    RIGHT_DOWN = 8
    RIGHT_UP = 16
    MIDDLE_DOWN = 32
    MIDDLE_UP = 64
end if

constant M_GET_MOUSE = 14,
	 M_MOUSE_EVENTS = 15,
	 M_MOUSE_POINTER = 24

global function get_mouse()
-- report mouse events,
-- returns -1 if no mouse event,
-- otherwise returns {event#, x-coord, y-coord}
    return machine_func(M_GET_MOUSE, 0)
end function

global procedure mouse_events(integer events)
-- select the mouse events to be reported by get_mouse()
-- e.g. mouse_events(LEFT_UP + LEFT_DOWN + RIGHT_DOWN)
    machine_proc(M_MOUSE_EVENTS, events)
end procedure

global procedure mouse_pointer(integer show_it)
-- show (1) or hide (0) the mouse pointer
    machine_proc(M_MOUSE_POINTER, show_it)
end procedure


