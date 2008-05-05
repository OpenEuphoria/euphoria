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

global sequence month_names, month_abbrs, day_names, day_abbrs, ampm

month_names = { "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December" }
month_abbrs = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
    "Aug", "Sep", "Oct", "Nov", "Dec" }
day_names = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
    "Saturday" }
day_abbrs = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
ampm = { "AM", "PM" }

global constant
    YEAR    = 1,
    MONTH   = 2,
    DAY     = 3,
    HOUR    = 4,
    MINUTE  = 5,
    SECOND  = 6,
    YEARS   = 1,
    MONTHS  = 2,
    DAYS    = 3,
    HOURS   = 4,
    MINUTES = 5,
    SECONDS = 6,
    WEEKS   = 7,
    DATE    = 8

global type datetime(object o)
	return sequence(o) and length(o) = 6
	    and integer(o[YEAR]) and integer(o[MONTH]) and integer(o[DAY])
	    and integer(o[HOUR]) and integer(o[MINUTE]) and atom(o[SECOND]
        and o[MONTH] >= 1 and o[MONTH] <= 12
        and o[DAY] >= 1 and o[DAY] <= daysInMonth(o[YEAR], o[MONTH])
        and o[HOUR] >= 0 and o[HOUR] <= 23
        and o[MINUTE] >= 0 and o[MINUTE] <= 59
        and o[SECOND] >= 0 and o[SECOND] < 60)
end type

-- Creates the datetime object for the specified parameters
global function new(integer year, integer month, integer day, integer hour, integer minute, atom second)
    datetime d
    d = {year, month, day, hour, minute, second}
    return d
end function

-- Converts the built-in date() format to datetime format
global function from_date(sequence src)
	return {src[YEAR]+1900, src[MONTH], src[DAY], src[HOUR], src[MINUTE], src[SECOND]}
end function

-- Returns the datetime object for now. No timezones!
global function now()
	return from_date(date())
end function

-- Answers the gregorian calendar day of the week.
global function dow(datetime dt)
    return remainder(julianDay(dt)-1+4094, 7) + 1
end function

-- TODO: document, test
global function doy(datetime dt)
    return julianDayOfYear({dt[YEAR], dt[MONTH], dt[DAY]})
end function

-- returns the number of seconds since 1970-1-1 0:0 (no timezone!)
global function to_unix(datetime dt)
	return datetimeToSeconds(dt) - EPOCH_1970
end function

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
                res &= month_abbrs[d[MONTH]]
            elsif ch = 'B' then
                res &= month_names[d[MONTH]]
            elsif ch = 'C' then
                res &= sprintf("%02d", d[YEAR] / 100)
            elsif ch = 'd' then
                res &= sprintf("%02d", d[DAY])
            elsif ch = 'H' then
                res &= sprintf("%02d", d[HOUR])
            elsif ch = 'I' then
                tmp = d[HOUR]
                if tmp > 12 then
                    tmp -= 12
                elsif tmp = 0 then
                    tmp = 12
                end if
                res &= sprintf("%02d", tmp)
            elsif ch = 'j' then
                res &= sprintf("%d", julianDayOfYear(d))
            elsif ch = 'k' then
                res &= sprintf("%d", d[HOUR])
            elsif ch = 'l' then
                tmp = d[HOUR]
                if tmp > 12 then
                    tmp -= 12
                elsif tmp = 0 then
                    tmp = 12
                end if
                res &= sprintf("%d", tmp)
            elsif ch = 'm' then
                res &= sprintf("%02d", d[MONTH])
            elsif ch = 'M' then
                res &= sprintf("%02d", d[MINUTE])
            elsif ch = 'p' then
                if d[HOUR] <= 12 then
                    res &= ampm[1]
                else
                    res &= ampm[2]
                end if
            elsif ch = 'P' then
                if d[HOUR] <= 12 then
                    res &= tolower(ampm[1])
                else
                    res &= tolower(ampm[2])
                end if
            elsif ch = 's' then
                res &= sprintf("%d", to_unix(d))
            elsif ch = 'S' then
                res &= sprintf("%02d", d[SECOND])
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
               tmp = floor(d[YEAR] / 100)
               res &= sprintf("%02d", d[YEAR] - (tmp * 100))
            elsif ch = 'Y' then
                res &= sprintf("%04d", d[YEAR])
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

global function add(datetime dt, object qty, integer interval)
    integer inc

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
        if qty > 0 then
            inc = 1
        else
            inc = -1
            qty = -(qty)
        end if

        for i = 1 to qty do
            if inc = 1 and dt[MONTH] = 12 then
                dt[MONTH] = 1
                dt[YEAR] += 1
            elsif inc = -1 and dt[MONTH] = 1 then
                dt[MONTH] = 12
                dt[YEAR] -= 1
            else
                dt[MONTH] += inc
            end if
        end for

        return dt
    elsif interval = YEARS then
        dt[YEAR] += qty
        if isLeap(dt[YEAR]) = 0 and dt[MONTH] = 2 and dt[DAY] = 29 then
            dt[MONTH] = 3
            dt[DAY] = 1
        end if

        return dt
    elsif interval = DATE then
        qty = datetimeToSeconds(qty)
    end if

	return secondsToDateTime(datetimeToSeconds(dt) + qty)
end function

global function subtract(datetime dt, atom qty, integer interval)
    return add(dt, -(qty), interval)
end function

-- returns the number of seconds between two datetimes
global function diff(datetime dt1, datetime dt2)
	return datetimeToSeconds(dt2) - datetimeToSeconds(dt1)
end function
