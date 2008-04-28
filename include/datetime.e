-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Date and Time functions

-- No timezone offset.
-- Engine created by CyrekSoft --

constant
    XLEAP = 1,
    Gregorian_Reformation = 1752,
    Gregorian_Reformation00 = 1700,
    DaysPerMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
    EPOCH_1970 = 62135856000,
    DayLengthInSeconds = 86400

global sequence month_names, month_abbrs, day_names, day_abbrs, ampm

month_names = { "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December" }
month_abbrs = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
    "Aug", "Sep", "Oct", "Nov", "Dec" }
day_names = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
    "Saturday" }
day_abbrs = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
ampm = { "AM", "PM" }


-- Helpers ------------------------------------------------------------------

function tolower(object x)
    return x + (x >= 'A' and x <= 'Z') * ('a' - 'A')
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

-- Conversions to and from seconds

function datetimeToSeconds(object dt) -- returns an atom
    return julianDay(dt) * DayLengthInSeconds + (dt[4] * 60 + dt[5]) * 60 + dt[6]
end function

function secondsToDateTime(atom seconds) -- returns a DateTime
    integer days, minutes, hours

    days = floor(seconds / DayLengthInSeconds)
    seconds = remainder(seconds, DayLengthInSeconds)

	hours = floor( seconds / 3600 )
	seconds -= hours * 3600
	
	minutes = floor( seconds / 60 )
	seconds -= minutes* 60
    return julianDate(days) & {hours, minutes, seconds}
end function

-- ================= START newstdlib

include string.e

global constant
    DT_YEAR   = 1,
    DT_MONTH  = 2,
    DT_DAY    = 3,
    DT_HOUR   = 4,
    DT_MINUTE = 5,
    DT_SECOND = 6,
    SECONDS   = 1,
    MINUTES   = 2,
    HOURS     = 3,
    DAYS      = 4,
    WEEKS     = 5,
    MONTHS    = 6,
    YEARS     = 7

global type datetime(object o)
	return sequence(o) and length(o) = 6
	    and integer(o[DT_YEAR]) and integer(o[DT_MONTH]) and integer(o[DT_DAY])
	    and integer(o[DT_HOUR]) and integer(o[DT_MINUTE]) and atom(o[DT_SECOND])
end type

-- Creates the datetime object for the specified parameters
global function new(integer year, integer month, integer day, integer hour, integer minute, atom second)
	return {year, month, day, hour, minute, second}
end function

-- TODO: document
-- Converts the built-in date() format to datetime format
global function from_date(sequence src)
	return {src[DT_YEAR]+1900, src[DT_MONTH], src[DT_DAY], src[DT_HOUR], src[DT_MINUTE], src[DT_SECOND]}
end function

-- TODO: document
-- Returns the datetime object for now. No timezones!
global function now()
	return from_date(date())
end function

-- TODO: document
-- Answers the gregorian calendar day of the week. 
global function dow(datetime dt)
    return remainder(julianDay(dt)-1+4094, 7) + 1
end function

-- TODO: document
-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function to_unix(datetime dt)
	return datetimeToSeconds(dt) - EPOCH_1970
end function

-- TODO: document
-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function from_unix(atom unix)
	return secondsToDateTime(EPOCH_1970 + unix)
end function

-- TODO: create, test, document
-- datetime parse(ustring string)
-- parse the string and returns the datetime
global function parse(ustring string)
	return 0
end function

-- TODO: create, document, test
-- ustring format(ustring format)
-- format the date according to the format string
-- format string some taken from date(1)
-- %%  a literal %
-- %a  locale's abbreviated weekday name (e.g., Sun)
-- %A  locale's full weekday name (e.g., Sunday)
-- %b  locale's abbreviated month name (e.g., Jan)
-- %B  locale's full month name (e.g., January)
-- %C  century; like %Y, except omit last two digits (e.g., 21)
-- %d  day of month (e.g, 01)
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
global function format(datetime d, ustring format)
    integer in_fmt, ch, tmp
    sequence res

    in_fmt = 0
    res = ""

    for i = 1 to length(format) do
        ch = format[i]

        if in_fmt then
            in_fmt = 0

            if ch = '%' then
                res &= '%'
            elsif ch = 'a' then
                res &= day_abbrs[dow(d)]
            elsif ch = 'A' then
                res &= day_names[dow(d)]
            elsif ch = 'b' then
                res &= month_abbrs[d[DT_MONTH]]
            elsif ch = 'B' then
                res &= month_names[d[DT_MONTH]]
            elsif ch = 'C' then
                res &= sprintf("%02d", d[DT_YEAR] / 100)
            elsif ch = 'd' then
                res &= sprintf("%02d", d[DT_DAY])
            elsif ch = 'H' then
                res &= sprintf("%02d", d[DT_HOUR])
            elsif ch = 'I' then
                tmp = d[DT_HOUR]
                if tmp > 12 then
                    tmp -= 12
                elsif tmp = 0 then
                    tmp = 12
                end if
                res &= sprintf("%02d", tmp)
            elsif ch = 'j' then
                res &= sprintf("%d", julianDayOfYear(d))
            elsif ch = 'k' then
                res &= sprintf("%d", d[DT_HOUR])
            elsif ch = 'l' then
                tmp = d[DT_HOUR]
                if tmp > 12 then
                    tmp -= 12
                elsif tmp = 0 then
                    tmp = 12
                end if
                res &= sprintf("%d", tmp)
            elsif ch = 'm' then
                res &= sprintf("%02d", d[DT_MONTH])
            elsif ch = 'M' then
                res &= sprintf("%02d", d[DT_MINUTE])
            elsif ch = 'p' then
                if d[DT_HOUR] <= 12 then
                    res &= ampm[1]
                else
                    res &= ampm[2]
                end if
            elsif ch = 'P' then
                if d[DT_HOUR] <= 12 then
                    res &= tolower(ampm[1])
                else
                    res &= tolower(ampm[2])
                end if
            elsif ch = 's' then
                res &= sprintf("%d", to_unix(d))
            elsif ch = 'S' then
                res &= sprintf("%02d", d[DT_SECOND])
            elsif ch = 'u' then
                tmp = dow(d)
                if tmp = 1 then
                    res &= "7" -- Sunday
                else
                    res &= sprintf("%d", dow(d) - 1)
                end if
            elsif ch = 'w' then
                res &= sprintf("%d", dow(d) - 1)
            elsif ch = 'y' then
               tmp = floor(d[DT_YEAR] / 100)
               res &= sprintf("%02d", d[DT_YEAR] - (tmp * 100))
            elsif ch = 'Y' then
                res &= sprintf("%04d", d[DT_YEAR])
            else
                -- TODO: error or just add?
            end if
        elsif ch = '%' then
            in_fmt = 1
        else
            res &= ch
        end if
    end for

	return res
end function

-- TODO: document
global function add(datetime dt, atom qty, integer interval)
    if interval = SECONDS then
    elsif interval = MINUTES then
        qty *= 60
    elsif interval = HOURS then
        qty *= 3600
    elsif interval = DAYS then
        qty *= 86400
    elsif interval = WEEKS then
        qty *= 604800
    elsif interval = MONTHS then
        -- TODO
    elsif interval = YEARS then
        -- TODO
    end if

	return secondsToDateTime(datetimeToSeconds(dt) + qty)
end function

-- TODO: document
global function subtract(datetime dt, atom qty, integer interval)
    return add(dt, -(qty), interval)
end function

-- TODO: document
-- returns the number of seconds between two datetimes
global function diff(datetime dt1, datetime dt2)
	return datetimeToSeconds(dt2) - datetimeToSeconds(dt1)
end function
