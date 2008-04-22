-- Date and Time functions
-- 2008

-- note 2008-04-23: ONLY CONTAINS FUNCTION PROTOTYPES

-- No timezone offset.

include string.e


global type datetime(object o)
	return 0 --TODO
end type

-- datetime datetime_new(int year, int month, int date, int hour, int minute, int second)
-- Creates the datetime object for the specified parameters
global function datetime_new(integer year, integer month, integer date, integer hour, integer minute, integer second)
	return 0 --TODO
end function
	

-- int datetime_compare(datetime dt1, datetime dt2)
-- Compare the receiver to the specified Date to determine the relative ordering. 
-- returns -1 or 0 or 1
global function datetime_compare(datetime dt1, datetime dt2)
	return 0 --TODO
end function
	
-- datetime datetime_from_date(object date)
-- Converts the built-in date() format to datetime format
global function datetime_from_date(object date)
	return 0 -- TODO
end function
	
-- datetime datetime_now()
-- Returns the datetime object for now. No timezones!
global function datetime_now()
	return datetime_from_date(date())
end function
	

-- int 	datetime_get_hour(datetime dt)
-- Answers the gregorian calendar hour of the day. 
global function datetime_get_hour(datetime dt)
	return 0 --TODO
end function

-- int 	datetime_get_minute(datetime dt)
-- Answers the gregorian calendar minute of the hour. 
global function datetime_get_minute(datetime dt)
	return 0 --TODO
end function

-- int 	datetime_get_second(datetime dt)
-- Answers the gregorian calendar second of the minute. 
global function datetime_get_second(datetime dt)
	return 0 --TODO
end function

-- int 	datetime_get_year()
-- Answers the gregorian calendar year since 1900. 
global function datetime_get_year(datetime dt)
	return 0 --TODO
end function

-- int 	datetime_get_month(datetime dt)
-- Answers the gregorian calendar month. 
global function datetime_get_month(datetime dt)
	return 0 --TODO
end function

-- int datetime_get_date(datetime dt)
-- Answers the gregorian calendar day of the month. 
global function datetime_get_date(datetime dt)
	return 0 --TODO
end function

-- int 	datetime_get_day(datetime dt)
-- Answers the gregorian calendar day of the week. 
global function datetime_get_day(datetime dt)
	return 0 --TODO
end function




-- datetime  datetime_set_hour(integer dt)
-- Sets the gregorian calendar hour of the day. 
global function datetime_set_hour(integer dt)
	return 0 --TODO
end function

-- datetime  datetime_set_minute(int dt)
-- Sets the gregorian calendar minute of the hour. 
global function datetime_set_minute(integer dt)
	return 0 --TODO
end function

-- datetime  datetime_set_second(int dt)
-- Sets the gregorian calendar second of the minute. 
global function datetime_set_second(integer dt)
	return 0 --TODO
end function

-- datetime  datetime_set_year()
-- Sets the gregorian calendar year since 1900. 
global function datetime_set_year(integer dt)
	return 0 --TODO
end function

-- datetime  datetime_set_month(datetime dt)
-- Sets the gregorian calendar month. 
global function datetime_set_month(integer dt)
	return 0 --TODO
end function

-- datetime datetime_set_date(datetime dt)
-- Sets the gregorian calendar day of the month. 
global function datetime_set_date(integer dt)
	return 0 --TODO
end function



-- datetime datetime_parse(ustring string)
-- parse the string and returns the datetime
global function datetime_parse(ustring string)
	return 0 --TODO
end function


-- ustring datetime_format(ustring format)
-- format the date according to the format string
-- format string some taken from date(1)
--  %%     a literal %
--  %a     locale's abbreviated weekday name (e.g., Sun)
--  %A     locale's full weekday name (e.g., Sunday)
--  %b     locale's abbreviated month name (e.g., Jan)
--  %B     locale's full month name (e.g., January)
--  %C     century; like %Y, except omit last two digits (e.g., 21)
--  %d     day of month (e.g, 01)
--  %g     last two digits of year of ISO week number (see %G)
--  %H     hour (00..23)
--  %I     hour (01..12)
--  %j     day of year (001..366)
--  %k     hour ( 0..23)
--  %l     hour ( 1..12)
--  %m     month (01..12)
--  %M     minute (00..59)
--  %p     locale's equivalent of either AM or PM; blank if not known
--  %P     like %p, but lower case
--  %s     seconds since 1970-01-01 00:00:00 UTC
--  %S     second (00..60)
--  %u     day of week (1..7); 1 is Monday
--  %w     day of week (0..6); 0 is Sunday
--  %y     last two digits of year (00..99)
--  %Y     year
global function datetime_format(ustring format)
	return 0 --TODO
end function


-- atom datetime_to_unix(datetime dt)
-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function datetime_to_unix(datetime dt)
	return 0 --TODO
end function

-- datetime datetime_add_second(datetime dt, atom seconds)
-- adds the date with specified number of seconds
global function datetime_add_second(datetime dt, atom seconds)
	return 0 --TODO
end function

-- datetime datetime_add_day(datetime dt, atom days)
-- adds the date with specified number of days
global function datetime_add_day(datetime dt, atom days)
	return 0 --TODO
end function

-- atom datetime_diff_second(datetime dt1, datetime dt2)
-- returns the number of seconds between two datetimes
global function datetime_diff_second(datetime dt1, datetime dt2)
	return 0 --TODO
end function

-- atom datetime_diff_day(datetime dt1, datetime dt2)
-- returns the number of days between two datetimes
global function datetime_diff_day(datetime dt1, datetime dt2)
	return 0 --TODO
end function

