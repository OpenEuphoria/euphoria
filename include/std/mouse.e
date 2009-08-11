-- (c) Copyright - See License.txt
--
namespace mouse

--****
-- == Mouse
--
-- <<LEVELTOC depth=2>>
--
-- === Requirements
--
-- * //Linux// ~-- you need GPM server to be running
-- * //Windows// ~-- not implemented yet for the text console
-- * //FreeBSD// ~-- not implemented
-- * //OS X// ~-- not implemented
--

--****
-- === Constants
--
-- The following constants can be used to identify and specify mouse events.
--

public integer MOVE, LEFT_DOWN, LEFT_UP, RIGHT_DOWN, RIGHT_UP,
	MIDDLE_DOWN, MIDDLE_UP, ANY_UP

ifdef UNIX then
	MOVE = 0
	LEFT_DOWN = 4
	LEFT_UP = 4
	RIGHT_DOWN = 1
	RIGHT_UP = 1
	MIDDLE_DOWN = 2
	MIDDLE_UP = 2
	ANY_UP = 35  -- LEFT, RIGHT or MIDDLE up (best you can do under xterm)
elsedef
	MOVE = 1
	LEFT_DOWN = 2
	LEFT_UP = 4
	RIGHT_DOWN = 8
	RIGHT_UP = 16
	MIDDLE_DOWN = 32
	MIDDLE_UP = 64
end ifdef

constant M_GET_MOUSE = 14,
		 M_MOUSE_EVENTS = 15,
		 M_MOUSE_POINTER = 24

--****
-- === Routines

--**
-- Queries the last mouse event.
--
-- Returns:
--		An **object**, either -1 if there has not 
-- been a mouse event since the last time ##get_mouse##() was called.
-- Otherwise, returns a triple ##{event, x, y}##.
--
-- Constants have been defined in mouse.e for the possible mouse events (the values for ##event##):
-- <eucode>
-- public constant 
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
-- Comments:
-- ##get_mouse##() returns immediately with either a -1 or a mouse event, without waiting for an event to occur. So, you must check it frequently enough to avoid missing an event:
-- when the next event occurs, the current event will be lost, if you haven't read it.
-- In practice it is not hard to catch almost all events. Losing a MOVE event is generally
-- not too serious, as the next MOVE will tell you where the mouse pointer is. 
--
-- Sometimes multiple events will be reported. For example, if the mouse is moving when the
-- left button is clicked, ##get_mouse##() will report an event value of LEFT_DOWN+MOVE, i.e.
-- 2+1 or 3. For this reason you should test for a particular event using [[:and_bits]](). See
-- examples below. Further, you can determine which events will be reported using [[:mouse_events]].
--
-- In //Linux//, no scaling is required - x and y correspond to the line and column on the screen,
-- with (1,1) at the top left. 
--
-- In //Linux//, mouse movement events are not reported in an xterm window, only in the text console.
--
-- In //Linux//, LEFT_UP, RIGHT_UP and MIDDLE_UP are not distinguishable from one another.
--
-- The first call that you make to ##get_mouse##() will turn on a mouse pointer, or a highlighted character.
--
-- The x,y coordinate returned could be that of the very tip of the mouse pointer or might refer to
-- the pixel pointed-to by the mouse pointer.
--
-- Example 1:
--   a return value of:
-- 	 ##{2, 100, 50}##
-- 	 would indicate that the left button was pressed down when the
--   mouse pointer was at location x=100, y=50 on the screen.
--
-- Example 2:
--   To test for LEFT_DOWN, write something like the following:
--
-- <eucode>
-- while 1 do
--     object event = get_mouse()
--     if sequence(event) then
--         if and_bits(event[1], LEFT_DOWN) then
--             -- left button was pressed
--             exit
--         end if
--     end if
-- end while
-- </eucode>
--
-- See Also:
--	[[:mouse_events]], [[: mouse_pointer]]

public function get_mouse()
	return machine_func(M_GET_MOUSE, 0)
end function

--**
-- Select the mouse events [[:get_mouse]]() is to report. 
--
-- Parameters:
--   # ##events##: an integer, all requested event codes or'ed together.
--
-- Comments:
-- By default, [[:get_mouse]]() will report all events. ##mouse_events##() can be called at various stages of the
-- execution of your program, as the need to detect events changes. Under //Unix//, ##mouse_events##() currently has no effect.
--
-- It is good practice to ignore events that you are not interested in, particularly the very
-- frequent MOVE event, in order to reduce the chance that you will miss a significant event. 
--
-- The first call that you make to ##mouse_events##() will turn on a mouse pointer, or a highlighted character.
--
-- Example 1:
-- <eucode>
-- mouse_events(LEFT_DOWN + LEFT_UP + RIGHT_DOWN)
-- </eucode>
--
-- will restrict get_mouse() to reporting the left button
-- being pressed down or released, and the right button
-- being pressed down. All other events will be ignored.
--
-- See Also:
--		[[:get_mouse]], [[: mouse_pointer]]

public procedure mouse_events(integer events)
	machine_proc(M_MOUSE_EVENTS, events)
end procedure

--**
-- Turn mouse pointer on or off.
--
-- Parameters:
--   # ##show_it## : an integer, 0 to hide and 1 to show.
--
-- Comments:
-- Multiple calls to hide
-- the pointer will require multiple calls to turn it back on. The
-- first call to either [[:get_mouse]]() or [[:mouse_events]]() will
-- also turn the pointer on (once).
--
-- Under //Linux//, [[:mouse_pointer]]() currently has no effect
--
-- It may be necessary to hide the mouse pointer temporarily when you
-- update the screen.
--
-- After a call to [[:text_rows]]() you may have to call [[:mouse_pointer]](1)
-- to see the mouse pointer again.
--
-- See Also:
--		[[:get_mouse]], [[:mouse_pointer]]

public procedure mouse_pointer(integer show_it)
	machine_proc(M_MOUSE_POINTER, show_it)
end procedure
