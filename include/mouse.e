-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Mouse
--

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

--**
-- Return the last mouse event in the form: ##{event, x, y}## or return ##-1## if there has not 
-- been a mouse event since the last time get_mouse() was called. 
--
-- Constants have been defined in mouse.e for the possible mouse events: 
-- <eucode>
-- global constant 
--     MOVE = 1,
--     LEFT_DOWN = 2,
--     LEFT_UP = 4,
--     RIGHT_DOWN = 8,
--     RIGHT_UP = 16,
--     MIDDLE_DOWN = 32,
--     MIDDLE_UP = 64
-- </eucode>
--
-- x and y are the coordinates of the mouse pointer at the time that the event occurred.
-- get_mouse() returns immediately with either a -1 or a mouse event. It does not wait
-- for an event to occur. You must check it frequently enough to avoid missing an event.
-- When the next event occurs, the current event will be lost, if you haven't read it.
-- In practice it is not hard to catch almost all events. Losing a MOVE event is generally
-- not too serious, as the next MOVE will tell you where the mouse pointer is. 

-- Sometimes multiple events will be reported. For example, if the mouse is moving when the
-- left button is clicked, get_mouse() will report an event value of LEFT_DOWN+MOVE, i.e.
-- 2+1 or 3. For this reason you should test for a particular event using and_bits(). See
-- examples below.
--
-- Comments:
-- In pixel-graphics modes that are 320 pixels wide, you need to divide the x value by 2 to get
-- the correct position on the screen. (A strange feature of DOS.)
--
-- In DOS32 text modes you need to scale the x and y coordinates to get line and column positions.
-- In Linux, no scaling is required - x and y correspond to the line and column on the screen,
-- with (1,1) at the top left. 
--
-- In DOS32, you need a DOS mouse driver to use this routine. In Linux, GPM Server must be running.
--
-- In Linux, mouse movement events are not reported in an xterm window, only in the text console. 
--
-- In Linux, LEFT_UP, RIGHT_UP and MIDDLE_UP are not distinguishable from one another. 
--
-- You can use get_mouse() in most text and pixel-graphics modes. 
--
-- The first call that you make to get_mouse() will turn on a mouse pointer, or a highlighted character.
--
-- DOS generally does not support the use of a mouse in SVGA graphics modes (beyond 640x480 pixels).
-- This restriction has been removed in Windows 95 (DOS 7.0). Graeme Burke, Peter Blue and others
-- have contributed mouse routines that get around the problems with using a mouse in SVGA. See
-- the Euphoria Archive Web page. 
--
-- The x,y coordinate returned could be that of the very tip of the mouse pointer or might refer to
-- the pixel pointed-to by the mouse pointer. Test this if you are trying to read the pixel color
-- using get_pixel(). You may have to read x-1,y-1 instead.
--
-- Example 1:
-- a return value of: 
-- 	{2, 100, 50}
-- 	would indicate that the left button was pressed down when the
-- mouse pointer was at location x=100, y=50 on the screen.
--
-- Example 2:
-- To test for LEFT_DOWN, write something like the following: 
-- 	object event
-- <eucode>
-- while 1 do
--     event = get_mouse()
--     if sequence(event) then
--         if and_bits(event[1], LEFT_DOWN) then
--             -- left button was pressed
--             exit
--         end if
--     end if
-- end while
-- </eucode>

global function get_mouse()
	return machine_func(M_GET_MOUSE, 0)
end function

--**
-- Use this procedure to select the mouse events that you want get_mouse() to report. By default,
-- get_mouse() will report all events. mouse_events() can be called at various stages of the
-- execution of your program, as the need to detect events changes. Under Linux, mouse_events()
-- currently has no effect.
--
-- Comments:
-- It is good practice to ignore events that you are not interested in, particularly the very
-- frequent MOVE event, in order to reduce the chance that you will miss a significant event. 
--
-- The first call that you make to mouse_events() will turn on a mouse pointer, or a highlighted character.
--
-- Example 1:
-- <eucode>
-- mouse_events(LEFT_DOWN + LEFT_UP + RIGHT_DOWN)
-- </eucode>

-- will restrict get_mouse() to reporting the left button
-- being pressed down or released, and the right button
-- being pressed down. All other events will be ignored.

global procedure mouse_events(integer events)
	machine_proc(M_MOUSE_EVENTS, events)
end procedure

--**
-- If i is 0 hide the mouse pointer, otherwise turn on the mouse pointer. Multiple calls to hide
-- the pointer will require multiple calls to turn it back on. The first call to either get_mouse()
-- or mouse_events(), will also turn the pointer on (once). Under Linux, mouse_pointer() currently
-- has no effect
--
-- Comments:
-- It may be necessary to hide the mouse pointer temporarily when you update the screen. 
--
-- After a call to text_rows() you may have to call mouse_pointer(1) to see the mouse pointer again.

global procedure mouse_pointer(integer show_it)
	machine_proc(M_MOUSE_POINTER, show_it)
end procedure

