-- Date and Time functions
-- 2008

-- note 2008-04-23: ONLY CONTAINS FUNCTION PROTOTYPES

-- No timezone offset.


-- Engine created by CyrekSoft --

-- Change this to 1 for extended leap year rules
constant XLEAP = 1
constant Gregorian_Reformation = 1752, Gregorian_Reformation00 = 1700,
DaysPerMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
constant 
YEAR  = 1, JDAY = 2,
EPOCH_1970 = 62135856000,
DayLengthInSeconds = 86400

-- Conversions to and from seconds

function hmsToSeconds(object dt) -- returns an atom
    return (dt[4] * 60 + dt[5]) * 60 + dt[6]
end function

-- Date Handling ------------------------------------------------------------

function isLeap(integer year) -- returns integer (0 or 1)
sequence ly
	ly = (remainder(year, {4, 100, 400, 3200, 80000})=0)
	
	if not ly[1] then return 0 end if
	
	if year <= Gregorian_Reformation then
		return 1 -- ly[1] can't possibly be 0 here so set shortcut as '1'.
	elsif XLEAP then
		return ly[1] - ly[2] + ly[3] - ly[4] + ly[5]
	else -- Standard Gregorian Calendar
		return ly[1] - ly[2] + ly[3]
	end if
end function

function daysInMonth(integer year, integer month) -- returns a month_
	if year = Gregorian_Reformation and month = 9 then
		return 19
	elsif month != 2 then
		return DaysPerMonth[month]
	else
		return DaysPerMonth[month] + isLeap(year)
	end if
end function

function daysInYear(integer year) -- returns a jday_ (355, 365 or 366)
	if year = Gregorian_Reformation then
		return 355
	end if
	return 365 + isLeap(year)
end function

-- Functions using the new data-types

function julianDayOfYear(object ymd) -- returns an integer
    integer year, month, day
    integer d

    year = ymd[1]
    month = ymd[2]
    day = ymd[3]

    if month = 1 then return day end if

    d = 0
    for i = 1 to month - 1 do
	d += daysInMonth(year, i)
    end for

    d += day

    if year = Gregorian_Reformation and month = 9 then
	if day > 13 then
	    d -= 11
	elsif day > 2 then
	    return 0
	end if
    end if

    return d
end function

function julianDay(object ymd) -- returns an integer
    integer year
    integer j, greg00

    year = ymd[1]
    j = julianDayOfYear(ymd)

    year  -= 1
    greg00 = year - Gregorian_Reformation00

    j += (
	365 * year
	+ floor(year/4)
	+ (greg00 > 0)
	    * (
		- floor(greg00/100)
		+ floor(greg00/400+.25)
	    )
	- 11 * (year >= Gregorian_Reformation)
    )

    if XLEAP then
	j += (
	    - (year >=  3200) * floor(year/ 3200)
	    + (year >= 80000) * floor(year/80000)
	)
    end if

    return j
end function


function julianDateInYear(object yd) -- returns a Date
    integer year, d
    year = yd[YEAR]
    d = yd[JDAY]

    -- guess month
    if d <= daysInMonth(year, 1) then
	return {year, 1, d}
    end if
    for month = 2 to 12 do
	d -= daysInMonth(year, month-1)
	if d <= daysInMonth(year, month) then
	    return {year, month, d}
	end if
    end for

    -- Skip to the next year on overflow
    -- The alternative is a crash, listed below
    return {year+1,1,d-31}
end function

function julianDate(integer j) -- returns a Date
    integer year, doy

    -- Take a guesstimate at the year -- this is usually v.close
    if j >= 0 then
	year = floor(j / (12 * 30.43687604)) + 1
    else
	year = -floor(-j / 365.25) + 1
    end if

    -- Calculate the day in the guessed year
    doy = j - (julianDay({year, 1, 1}) - 1) -- = j - last day of prev year

    -- Correct any errors

    -- The guesstimate is usually so close that these whiles could probably
    -- be made into ifs, but I haven't checked all possible dates yet... ;)

    while doy <= 0 do -- we guessed too high for the year
	year -= 1
	doy += daysInYear(year)
    end while

    while doy > daysInYear(year) do -- we guessed too low
	doy -= daysInYear(year)
	year += 1
    end while

    -- guess month
    if doy <= daysInMonth(year, 1) then
	return {year, 1, doy}
    end if
    for month = 2 to 12 do
	doy -= daysInMonth(year, month-1)
	if doy <= daysInMonth(year, month) then
	    return {year, month, doy}
	end if
    end for

    -- Skip to the next year on overflow
    -- The alternative is a crash, listed below
    return {year+1, 1, doy-31}
end function

-- Day of week

function clock7(integer number) -- returns an integer (1..7)
    return remainder(number+4094, 7)+1
    -- modulo(number-1, 7)+1 would be better. Hence adding a few multiples
    --   of 7 to the -1 in the remainder() call
end function

-- Conversions to and from seconds

function datetimeToSeconds(object dt) -- returns an atom
    return julianDay(dt) * DayLengthInSeconds + hmsToSeconds(dt)
end function

function secondsToDateTime(atom seconds) -- returns a DateTime
integer days, minutes, hours
atom secs

    days = floor(seconds / DayLengthInSeconds)
    seconds = remainder(seconds, DayLengthInSeconds)

    secs = remainder(seconds, 60)
    seconds = floor(seconds / 60)
    minutes = remainder(seconds, 60)
    hours = remainder(floor(seconds / 60), 24)
    
    return julianDate(days) & {hours, minutes, seconds}
end function


-- ================= START newstdlib

include string.e


global type datetime(object o)
	return sequence(o) and length(o) = 6
	and integer(o[1]) and integer(o[2]) and integer(o[3]) 
	and integer(o[4]) and integer(o[5]) and atom(o[6]) 
end type

-- datetime datetime_new(int year, int month, int date, int hour, int minute, int second)
-- Creates the datetime object for the specified parameters
global function datetime_new(integer year, integer month, integer date, integer hour, integer minute, atom second)
	return {year, month, date, hour, minute, second}
end function


-- int datetime_compare(datetime dt1, datetime dt2)
-- Compare the receiver to the specified Date to determine the relative ordering. 
-- returns -1 or 0 or 1
global function datetime_compare(datetime dt1, datetime dt2)
    return compare(datetimeToSeconds(dt2) - datetimeToSeconds(dt1), 0)
end function
	
-- datetime datetime_from_date(object date)
-- Converts the built-in date() format to datetime format
global function datetime_from_date(object src)
	return {src[1]+1900, src[2], src[3], src[4], src[5], src[6]}
end function
	
-- datetime datetime_now()
-- Returns the datetime object for now. No timezones!
global function datetime_now()
	return datetime_from_date(date())
end function


-- int 	datetime_get_year()
-- Answers the gregorian calendar year since 1900. 
global function datetime_get_year(datetime dt)
	return dt[1]
end function

-- int 	datetime_get_month(datetime dt)
-- Answers the gregorian calendar month. 
global function datetime_get_month(datetime dt)
	return dt[2]
end function

-- int datetime_get_date(datetime dt)
-- Answers the gregorian calendar day of the month. 
global function datetime_get_date(datetime dt)
	return dt[3]
end function

-- int 	datetime_get_hour(datetime dt)
-- Answers the gregorian calendar hour of the day. 
global function datetime_get_hour(datetime dt)
	return dt[4]
end function

-- int 	datetime_get_minute(datetime dt)
-- Answers the gregorian calendar minute of the hour. 
global function datetime_get_minute(datetime dt)
	return dt[5]
end function

-- atom datetime_get_second(datetime dt)
-- Answers the gregorian calendar second of the minute. 
global function datetime_get_second(datetime dt)
	return dt[6]
end function

-- int 	datetime_get_day(datetime dt)
-- Answers the gregorian calendar day of the week. 
global function datetime_get_day(datetime dt)
    return clock7(julianDay(dt)-1)
end function



-- datetime datetime_set_year()
-- Sets the gregorian calendar year. 
global function datetime_set_year(datetime dt, integer n)
	dt[1] = n
	return dt
end function

-- datetime datetime_set_month(datetime dt)
-- Sets the gregorian calendar month. 
global function datetime_set_month(datetime dt, integer n)
	dt[2] = n
	return dt
end function

-- datetime datetime_set_date(datetime dt)
-- Sets the gregorian calendar day of the month. 
global function datetime_set_date(datetime dt, integer n)
	dt[3] = n
	return dt
end function

-- datetime datetime_set_hour(integer dt)
-- Sets the gregorian calendar hour of the day. 
global function datetime_set_hour(datetime dt, integer n)
	dt[4] = n
	return dt
end function

-- datetime datetime_set_minute(int dt)
-- Sets the gregorian calendar minute of the hour. 
global function datetime_set_minute(datetime dt, integer n)
	dt[5] = n
	return dt
end function

-- datetime datetime_set_second(int dt)
-- Sets the gregorian calendar second of the minute. 
global function datetime_set_second(datetime dt, atom n)
	dt[6] = n
	return dt
end function



-- datetime datetime_parse(ustring string)
-- parse the string and returns the datetime
global function datetime_parse(ustring string)
	return 0 --TODO
end function


-- ustring datetime_format(ustring format)
-- format the date according to the format string
-- format string some taken from date(1)
-- %%  a literal %
-- %a  locale's abbreviated weekday name (e.g., Sun)
-- %A  locale's full weekday name (e.g., Sunday)
-- %b  locale's abbreviated month name (e.g., Jan)
-- %B  locale's full month name (e.g., January)
-- %C  century; like %Y, except omit last two digits (e.g., 21)
-- %d  day of month (e.g, 01)
-- %g  last two digits of year of ISO week number (see %G)
-- %H  hour (00..23)
-- %I  hour (01..12)
-- %j  day of year (001..366)
-- %k  hour ( 0..23)
-- %l  hour ( 1..12)
-- %m  month (01..12)
-- %M  minute (00..59)
-- %p  locale's equivalent of either AM or PM; blank if not known
-- %P  like %p, but lower case
-- %s  seconds since 1970-01-01 00:00:00 UTC
-- %S  second (00..60)
-- %u  day of week (1..7); 1 is Monday
-- %w  day of week (0..6); 0 is Sunday
-- %y  last two digits of year (00..99)
-- %Y  year
global function datetime_format(ustring format)
	return 0 --TODO
end function


-- atom datetime_to_unix(datetime dt)
-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function datetime_to_unix(datetime dt)
	return datetimeToSeconds(dt) - EPOCH_1970
end function


-- datetime datetime_from_unix(atom unix)
-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function datetime_from_unix(atom unix)
	return secondsToDateTime(EPOCH_1970 + unix)
end function



-- datetime datetime_add_second(datetime dt, atom seconds)
-- adds the date with specified number of seconds
global function datetime_add_second(datetime dt, atom seconds)
	return secondsToDateTime(datetimeToSeconds(dt) + seconds)
end function

-- datetime datetime_add_day(datetime dt, integer days)
-- adds the date with specified number of days
global function datetime_add_day(datetime dt, integer days)
	return secondsToDateTime(datetimeToSeconds(dt) + days * DayLengthInSeconds)
end function

-- atom datetime_diff_second(datetime dt1, datetime dt2)
-- returns the number of seconds between two datetimes
global function datetime_diff_second(datetime dt1, datetime dt2)
	return datetimeToSeconds(dt2) - datetimeToSeconds(dt1)
end function

-- atom datetime_diff_day(datetime dt1, datetime dt2)
-- returns the number of days between two datetimes
global function datetime_diff_day(datetime dt1, datetime dt2)
	return julianDay(dt2) - julianDay(dt1)
end function

