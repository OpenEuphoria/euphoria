--****
-- == Date and Time
--
-- <<LEVELTOC level=2 depth=4>>

namespace datetime

integer yydiff = 80

include std/dll.e
include std/get.e
include std/machine.e
include std/types.e

ifdef LINUX then
	constant gmtime_ = dll:define_c_func(dll:open_dll(""), "gmtime", {dll:C_POINTER}, dll:C_POINTER)
	constant time_ = dll:define_c_func(dll:open_dll(""), "time", {dll:C_POINTER}, dll:C_POINTER)
elsifdef OSX then
	constant gmtime_ = dll:define_c_func(dll:open_dll("libc.dylib"), "gmtime", {dll:C_POINTER}, dll:C_POINTER)
	constant time_ = dll:define_c_func(dll:open_dll("libc.dylib"), "time", {dll:C_POINTER}, dll:C_INT)
elsifdef WINDOWS then
	constant gmtime_ = dll:define_c_func(dll:open_dll("msvcrt.dll"), "+gmtime", {dll:C_POINTER}, dll:C_POINTER)
	constant time_ = dll:define_c_proc(dll:open_dll("kernel32.dll"), "GetSystemTimeAsFileTime", {dll:C_POINTER})
elsifdef UNIX then
	constant gmtime_ = dll:define_c_func(dll:open_dll("libc.so"), "gmtime", {dll:C_POINTER}, dll:C_POINTER)
	constant time_ = dll:define_c_func(dll:open_dll("libc.so"), "time", {dll:C_POINTER}, dll:C_INT)
end ifdef

enum TM_SEC, TM_MIN, TM_HOUR, TM_MDAY, TM_MON, TM_YEAR --, TM_WDAY, TM_YDAY, TM_ISDST

function time()
	ifdef WINDOWS then
		atom ptra, valhi, vallow, deltahi, deltalow
		deltahi = 27111902
		deltalow = 3577643008
		ptra = machine:allocate(8)
		c_proc(time_, {ptra})
		vallow = peek4u(ptra)
		valhi = peek4u(ptra+4)
		machine:free(ptra)
		vallow -= deltalow
		valhi -= deltahi
		if vallow < 0 then
			vallow += power(2, 32)
			valhi -= 1
		end if
		return floor(((valhi * power(2,32)) + vallow) / 10000000)
	elsedef
		return c_func(time_, {dll:NULL})
	end ifdef
end function

function gmtime(atom time)
	sequence ret
	atom timep, tm_p
	integer n

	timep = machine:allocate( sizeof( C_POINTER ) )
	poke_pointer(timep, time)
	
	tm_p = c_func(gmtime_, {timep})
	
	machine:free(timep)
	if tm_p != 0 then
		return peek4s(tm_p & 9 )
	else
		return repeat( 0, 9 )
	end if
end function

constant
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
		else
				return ly[1] - ly[2] + ly[3] - ly[4] + ly[5]
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

	if year >= 3200 then
		j -= floor(year/ 3200)
		if year >= 80000 then
			j += floor(year/80000)
		end if
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

--****
-- === Localized Variables

--**
-- Month Names

public sequence month_names = { 
	"January", "February", "March", "April", "May", "June", 
	"July", "August", "September", "October", "November", "December" 
}

--**
-- Abbreviations of Month Names

public sequence month_abbrs = { 
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec" 
}

--**
-- Day Names

public sequence day_names = { 
	"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
	"Saturday" 
}

--**
-- Abbreviations of Day Names

public sequence day_abbrs = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }

--**
-- AM and PM

public sequence ampm = { "AM", "PM" }

--****
-- === Date and Time Type Accessors
--
-- These accessors can be used with the [[:datetime]] type.

public enum	
	--**
	-- Year (full year, i.e. 2010, 1922, )
	
	YEAR, 
	
	--**
	-- Month (1-12)
	
	MONTH, 
	
	--**
	-- Day (1-31)
	
	DAY, 
	
	--**
	-- Hour (0-23)
	
	HOUR,
		
	--**
	-- Minute (0-59)
	
	MINUTE,
		
	--**
	-- Second (0-59)
	
	SECOND

--****
-- === Intervals
--
-- These constant enums are to be used with the [[:add]] and [[:subtract]] routines.
--

public enum 
	--**
	-- Years
	YEARS,
		
	--**
	-- Months
	MONTHS, 

	--**
	-- Weeks
	WEEKS, 

	--**
	-- Days
	DAYS,
	
	--**
	-- Hours
	HOURS,
	
	--**
	-- Minutes
	MINUTES, 

	--**
	-- Seconds
	SECONDS, 

	--**
	-- Date
	DATE

--****
-- === Types

--**
-- datetime type
--
-- Parameters:
--   # ##obj## : any object, so no crash takes place.
--
-- Comments:
-- A datetime type consists of a sequence of length six in the form
-- ##{year, month, day_of_month, hour, minute, second}##. Checks are made to guarantee
-- those values are in range. 
-- 
-- Note:
-- All elements must be integers except for
-- seconds which could either integer or atom values.

public type datetime(object o)
	if atom(o) then return 0 end if

	if length(o) != 6 then return 0 end if

	if not integer(o[YEAR]) then return 0 end if

	if not integer(o[MONTH]) then return 0 end if

	if not integer(o[DAY]) then return 0 end if

	if not integer(o[HOUR]) then return 0 end if

	if not integer(o[MINUTE]) then return 0 end if

	if not atom(o[SECOND]) then return 0 end if

	if not equal(o[1..3], {0,0,0}) then
		-- Special case of all zeros is allowed; used when the data is a time only.
		if o[MONTH] < 1 then return 0 end if

		if o[MONTH] > 12 then return 0 end if

		if o[DAY] < 1 then return 0 end if

		if o[DAY] > daysInMonth(o[YEAR],o[MONTH]) then return 0 end if
	end if

	if o[HOUR] < 0 then return 0 end if

	if o[HOUR] > 23 then return 0 end if

	if o[MINUTE] < 0 then return 0 end if

	if o[MINUTE] > 59 then return 0 end if

	if o[SECOND] < 0 then return 0 end if

	if o[SECOND] >= 60 then return 0 end if

	return 1
end type

--****
-- === Routines

--****
-- Signature:
-- <built-in> function time()
--
-- Description:
--   returns the number of seconds since some fixed point in the past.
--
-- Returns:
--   An **atom**, which represents an absolute number of seconds.
--
-- Comments: 
--   Take the difference between two readings of ##time()## to measure, for example, how long 
--   a section of code takes to execute.
--
--   On some machines, ##time()## can return a negative number. However, you can still use the
--   difference in calls to ##time()## to measure elapsed time.
--
-- Example 1:
-- <eucode>
-- constant ITERATIONS = 1000000
-- integer p
-- atom t0, loop_overhead
-- 
-- t0 = time()
-- for i = 1 to ITERATIONS do
--     -- time an empty loop
-- end for
-- loop_overhead = time() - t0
-- 
-- t0 = time()
-- for i = 1 to ITERATIONS do
--     p = power(2, 20)
-- end for
-- ? (time() - t0 - loop_overhead)/ITERATIONS
-- -- calculates time (in seconds) for one call to power
-- </eucode>
--
-- See Also: 
-- [[:date]], [[:now]]
 
--****
-- Signature:
-- <built-in> function date()
--
-- Description:
-- returns a sequence with information on the current date.
--
-- Returns:
-- A **sequence** of length 8, laid out as follows~:
-- # year  ~-- since 1900
-- # month ~-- January = 1
-- # day   ~-- day of month, starting at 1
-- # hour  ~-- 0 to 23
-- # minute ~-- 0 to 59
-- # second ~-- 0 to 59
-- # day of the week ~-- Sunday = 1
-- # day of the year ~-- January 1st = 1
--
-- Comments:
-- The value returned for the year is actually the number of years since 1900 (not the last 2 digits of the year). 
-- In the year 2000 this value was 100. In 2001 it was 101, and so on.
--  
-- Example 1:
--
-- <eucode>
-- now = date()
-- -- now has: {95,3,24,23,47,38,6,83}
-- -- i.e. Friday March 24, 1995 at 11:47:38pm, day 83 of the year
-- </eucode>
--
-- See Also:
--  [[:time]], [[:now]]

--**
-- converts a sequence formatted according to the built-in ##date## function to a valid datetime
-- sequence.
--
-- Parameters:
--   # ##src## : a sequence which ##date## might have returned
--
-- Returns:
--   A **sequence**, more precisely a **datetime** corresponding to the same moment 
--   in time.
--
-- Example 1:
-- <eucode>
-- d = from_date(date())
-- -- d is the current date and time
-- </eucode>
--
-- See Also:
--     [[:date]], [[:from_unix]], [[:now]], [[:new]]

public function from_date(sequence src)
	return {src[YEAR]+1900, src[MONTH], src[DAY], src[HOUR], src[MINUTE], src[SECOND]}
end function

--**
-- creates a new datetime value initialized with the current date and time.
--
-- Returns:
--   A **sequence**, more precisely a **datetime** corresponding to the current 
--   moment in time.
--
-- Example 1:
-- <eucode>
-- dt = now()
-- -- dt is the current date and time
-- </eucode>
--
-- See Also:
--     [[:from_date]], [[:from_unix]], [[:new]], [[:new_time]], [[:now_gmt]]

public function now()
	return from_date(date())
end function

--**
-- create a new datetime value that falls into the Greenwich Mean Time (GMT) timezone.
--
-- Comments:
-- This function will return a datetime that is GMT no matter what timezone the system
-- is running under.
--
-- Example 1:
-- <eucode>
-- dt = now_gmt()
-- -- If local time was July 16th, 2008 at 10:34pm CST
-- -- dt would be July 17th, 2008 at 03:34pm GMT
-- </eucode>
--
-- See Also:
-- [[:now]]

public function now_gmt()
	sequence t1 = gmtime(time())

	return { 
		t1[TM_YEAR] + 1900, t1[TM_MON] + 1, t1[TM_MDAY], 
		t1[TM_HOUR], t1[TM_MIN], t1[TM_SEC]
	}
end function

--**
-- creates a new datetime value.
--
-- !! TODO: test default parameter usage
--
-- Parameters:
--   # ##year##   ~-- the full year.
--   # ##month##  ~-- the month (1-12).
--   # ##day##    ~-- the day of the month (1-31).
--   # ##hour##   ~-- the hour (0-23) (defaults to 0)
--   # ##minute## ~-- the minute (0-59) (defaults to 0)
--   # ##second## ~-- the second (0-59) (defaults to 0)
--
-- Example 1:
-- <eucode>
-- dt = new(2010, 1, 1, 0, 0, 0)
-- -- dt is Jan 1st, 2010
-- </eucode>
--
-- See Also:
--     [[:from_date]], [[:from_unix]], [[:now]], [[:new_time]]

public function new(integer year=0, integer month=0, integer day=0,
			integer hour=0, integer minute=0, atom second=0)
	datetime d
	d = {year, month, day, hour, minute, second}
	if equal(d, {0,0,0,0,0,0}) then
		return now()
	else
		return d
	end if
end function

--**
-- creates a new datetime value with a date of zeros.
--
-- Parameters:
--   # ##hour## : is the hour (0-23)
--   # ##minute## : is the minute (0-59)
--   # ##second## : is the second (0-59)
--
-- Example 1:
-- <eucode>
-- dt = new_time(10, 30, 55)
-- dt is 10:30:55 AM
-- </eucode>
--
-- See Also:
--     [[:from_date]], [[:from_unix]], [[:now]], [[:new]]

public function new_time(integer hour, integer minute, atom second)
	return new(0, 0, 0, hour, minute, second)
end function

--**
-- gets the day of week of the datetime ##dt##.
--
-- Parameters:
--    # ##dt## : a datetime to be queried.
--
-- Returns:
--    An **integer**, between 1 (Sunday) and 7 (Saturday).
--
-- Example 1:
-- <eucode>
-- d = new(2008, 5, 2, 0, 0, 0)
-- day = weeks_day(d) -- day is 6 because May 2, 2008 is a Friday.
-- </eucode>

public function weeks_day(datetime dt)
	return remainder(julianDay(dt)-1+4094, 7) + 1
end function

--**
-- gets the Julian day of year of the supplied date.
--
-- Parameters:
--   # ##dt## : a datetime to be queried.
--
-- Returns:
--   An **integer**, between 1 and 366.
--
-- Comments:
--   For dates earlier than 1800, this routine may give inaccurate results if the date
--   applies to a country other than United Kingdom or a former colony thereof. The 
--   change from Julian to Gregorian calendar took place much earlier in some other 
--   European countries.
--
-- Example 1:
-- <eucode>
-- d = new(2008, 5, 2, 0, 0, 0)
-- day = years_day(d) -- day is 123
-- </eucode>

public function years_day(datetime dt)
	return julianDayOfYear({dt[YEAR], dt[MONTH], dt[DAY]})
end function

--**
-- determines if ##dt## falls within leap year.
--
-- Parameters:
--   # ##dt## : a datetime to be queried.
--
-- Returns:
--   An **integer**, of 1 if leap year, otherwise 0.
--
-- Example 1:
-- <eucode>
-- d = new(2008, 1, 1, 0, 0, 0)
-- ? is_leap_year(d) -- prints 1
-- d = new(2005, 1, 1, 0, 0, 0)
-- ? is_leap_year(d) -- prints 0
-- </eucode>
--
-- See Also:
--   [[:days_in_month]]

public function is_leap_year(datetime dt)
	return isLeap(dt[YEAR])
end function

--**
-- returns the number of days in the month of ##dt##.
--
-- Comments:
-- This takes into account leap year.
--
-- Parameters:
--   # ##dt## : a datetime to be queried.
--
-- Example 1:
-- <eucode>
-- d = new(2008, 1, 1, 0, 0, 0)
-- ? days_in_month(d) -- 31
-- d = new(2008, 2, 1, 0, 0, 0) -- Leap year
-- ? days_in_month(d) -- 29
-- </eucode>
--
-- See Also:
--   [[:is_leap_year]]

public function days_in_month(datetime dt)
	return daysInMonth(dt[YEAR], dt[MONTH])
end function

--**
-- returns the number of days in the year of ##dt##.
--
-- Comments:
-- This takes into account leap year.
--
-- Parameters:
--   # ##dt## : a datetime to be queried.
--
-- Example 1:
-- <eucode>
-- d = new(2007, 1, 1, 0, 0, 0)
-- ? days_in_year(d) -- 365
-- d = new(2008, 1, 1, 0, 0, 0) -- leap year
-- ? days_in_year(d) -- 366
-- </eucode>
--
-- See Also:
--   [[:is_leap_year]], [[:days_in_month]]

public function days_in_year(datetime dt)
	return daysInYear(dt[YEAR])
end function

--**
-- converts a datetime value to the //Unix// numeric format (seconds since ##EPOCH_1970##).
--
-- Parameters:
--   # ##dt## : a datetime to be queried.
--
-- Returns:
--   An **atom**, so this will not overflow during the winter 2038-2039.
--
--
-- Example 1:
-- <eucode>
-- secs_since_epoch = to_unix(now())
-- -- secs_since_epoch is equal to the current seconds since epoch
-- </eucode>
--
-- See Also:
--     [[:from_unix]], [[:format]]

public function to_unix(datetime dt)
	return datetimeToSeconds(dt) - EPOCH_1970
end function

--**
-- creates a datetime value from the //Unix// numeric format (seconds since EPOCH).
--
-- Parameters:
--   # ##unix## : an atom, counting seconds elapsed since EPOCH.
--
-- Returns:
--   A **sequence**, more precisely a **datetime** representing the same moment 
--   in time.
--
-- Example 1:
-- <eucode>
-- d = from_unix(0)
-- -- d is 1970-01-01 00:00:00  (zero seconds since EPOCH)
-- </eucode>
--
-- See Also:
--     [[:to_unix]], [[:from_date]], [[:now]], [[:new]]

public function from_unix(atom unix)
	return secondsToDateTime(EPOCH_1970 + unix)
end function

--**
-- formats the date according to the format pattern string.
--
-- Parameters:
--   # ##d## : a datetime which is to be printed out
--   # ##pattern## : a format string, similar to the ones ##sprintf## uses, but with 
--     some Unicode encoding. The default is ##"%Y-%m-%d %H:%M:%S"##.
--
-- Returns:
--  A **string**, with the date ##d## formatted according to the specification in ##pattern##.
--
-- Comments:
-- Pattern string can include the following specifiers~:
--
-- * ##~%%## ~-- a literal %
-- * ##%a## ~-- locale's abbreviated weekday name (e.g., Sun)
-- * ##%A## ~-- locale's full weekday name (e.g., Sunday)
-- * ##%b## ~-- locale's abbreviated month name (e.g., Jan)
-- * ##%B## ~-- locale's full month name (e.g., January)
-- * ##%C## ~-- century; like %Y, except omit last two digits (e.g., 21)
-- * ##%d## ~-- day of month (e.g, 01)
-- * ##%H## ~-- hour (00..23)
-- * ##%I## ~-- hour (01..12)
-- * ##%j## ~-- day of year (001..366)
-- * ##%k## ~-- hour ( 0..23)
-- * ##%l## ~-- hour ( 1..12)
-- * ##%m## ~-- month (01..12)
-- * ##%M## ~-- minute (00..59)
-- * ##%p## ~-- locale's equivalent of either AM or PM; blank if not known
-- * ##%P## ~-- like %p, but lower case
-- * ##%s## ~-- seconds since 1970-01-01 00:00:00 UTC
-- * ##%S## ~-- second (00..60)
-- * ##%u## ~-- day of week (1..7); 1 is Monday
-- * ##%w## ~-- day of week (0..6); 0 is Sunday
-- * ##%y## ~-- last two digits of year (00..99)
-- * ##%Y## ~-- year
--
-- Example 1:
-- <eucode>
-- d = new(2008, 5, 2, 12, 58, 32)
-- s = format(d, "%Y-%m-%d %H:%M:%S")
-- -- s is "2008-05-02 12:58:32"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- d = new(2008, 5, 2, 12, 58, 32)
-- s = format(d, "%A, %B %d '%y %H:%M%p")
-- -- s is "Friday, May 2 '08 12:58PM"
-- </eucode>
--
-- See Also:
--     [[:to_unix]], [[:parse]]
--

public function format(datetime d, sequence pattern = "%Y-%m-%d %H:%M:%S")
	integer in_fmt, ch, tmp
	sequence res

	in_fmt = 0
	res = ""

	for i = 1 to length(pattern) do
		ch = pattern[i]

		if in_fmt then
			in_fmt = 0

			if ch = '%' then
				res &= '%'
			elsif ch = 'a' then
				res &= day_abbrs[weeks_day(d)]
			elsif ch = 'A' then
				res &= day_names[weeks_day(d)]
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
				tmp = weeks_day(d)
				if tmp = 1 then
					res &= "7" -- Sunday
				else
					res &= sprintf("%d", weeks_day(d) - 1)
				end if
			elsif ch = 'w' then
				res &= sprintf("%d", weeks_day(d) - 1)
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

--
-- Used to determine how to handle %y in parse()
--

constant date_now = now()

--**
-- parses a datetime string according to the given format.
--
-- Parameters:
--   # ##val## : string datetime value
--   # ##fmt## : datetime format. Default is ##"%Y-%m-%d %H:%M:%S"##
--   # ##yysplit## : Set the maximum difference from the current year when parsing
--     a two digit year. Defaults to -80/+20.
--
-- Returns:
--	A **datetime**, value.
-- 
-- Comments:
--   Only a subset of the format specification is currently supported~:
--
--   * ##%d## ~--  day of month (e.g, 01)
--   * ##%H## ~--  hour (00..23)
--   * ##%m## ~--  month (01..12)
--   * ##%M## ~--  minute (00..59)
--   * ##%S## ~--  second (00..60)
--   * ##%y## ~--  2-digit year (YY)
--   * ##%Y## ~--  4-digit year (CCYY)
--
--   More format codes will be added in future versions.
--  
--   All non-format characters in the format string are ignored and are not
--   matched against the input string.
--
--   All non-digits in the input string are ignored.
--
-- Parsing Two Digit Years~:
--
--   When parsing a two digit year ##parse## has to make a decision if a given year
--   is in the past or future. For example, 10/18/44. Is that Oct 18, 1944 or
--   Oct 18, 2044. A common rule has come about for this purpose and that is the -80/+20 
--   rule. Based on research it was found that more historical events are recorded than
--   future events, thus it favors history rather than future. Some other applications may
--   require a different rule, thus the ##yylower## parameter can be supplied.
--
--   Assuming today is 12/22/2010 here is an example of the -80/+20 rule~:
--   || YY || Diff   || CCYY ||
--   | 18   | -92/+8  |  2018 |
--   | 95   | -15/+85 |  1995 |
--   | 33   | -77/+23 |  1933 |
--   | 29   | -81/+19 |  2029 |
--
--   Another rule in use is the -50/+50 rule. Therefore, if you supply -50 to the ##yylower## 
--   to set the lower bounds, some examples may be (given that today is 12/22/2010)~:
--   || YY || Diff   || CCYY ||
--   | 18   | -92/+8  |  2018 |
--   | 95   | -15/+85 |  1995 |
--   | 33   | -77/+23 |  2033 |
--   | 29   | -81/+19 |  2029 |
--
-- Note:
--   * Since 4.0.1 ~-- 2-digit year parsing and ##yylower## parameter.
--
-- Example 1:
-- <eucode>
-- datetime d = parse("05/01/2009 10:20:30", "%m/%d/%Y %H:%M:%S")
-- -- d is { 2009, 5, 1, 10, 20, 30 }
-- </eucode>
--
-- Example 2:
-- <eucode>
-- datetime d = parse("05/01/44", "%m/%d/%y", -50) -- -50/+50 rule
-- -- d is { 2044, 5, 14, 0, 0, 0 }
-- </eucode>
--
-- See Also:
--   [[:format]]
--

public function parse(sequence val, sequence fmt="%Y-%m-%d %H:%M:%S", integer yylower = -80)
	integer fpos = 1, spos = 1, maxlen, rpos 
	sequence res = {0,0,0,0,0,0}

	while fpos <= length(fmt) do
		if fmt[fpos] = '%' then
			fpos += 1

			switch fmt[fpos] do
				case 'Y' then
					rpos = 1
					maxlen = 4

				case 'y' then
					rpos = 1
					maxlen = 2

				case 'm' then
					rpos = 2
					maxlen = 2

				case 'd' then
					rpos = 3
					maxlen = 2

				case 'H' then
					rpos = 4
					maxlen = 2

				case 'M' then
					rpos = 5
					maxlen = 2

				case 'S' then
					rpos = 6
					maxlen = 2

				case else
					-- Ignore any invalid format character.
					rpos = 0
					
			end switch
			
			if rpos then
				sequence got
				integer epos
				while spos <= length(val) do
					if types:t_digit(val[spos]) then
						exit
					end if
					spos += 1
				end while
			    
				epos = spos + 1
				while epos <= length(val) and epos < spos + maxlen do
					if not types:t_digit(val[epos]) then
						exit
					end if
					epos += 1
				end while
				
				if spos > length(val) then
					return -1
				end if
				got = stdget:value(val[spos .. epos-1], , stdget:GET_LONG_ANSWER)
				if got[1] != stdget:GET_SUCCESS then
					return -1
				end if

				-- If this is a 2 digit year we have to do some special handling
				if fmt[fpos] = 'y' then
					-- Adjust the date to be not more than yysplit years ago
					integer century = floor(date_now[YEAR] / 100) * 100
					integer year = got[2] + (century - 100)
					if year < (date_now[YEAR] + yylower) then
						year = got[2] + century
					end if

					got[2] = year
				end if

				res[rpos] = got[2]
				spos = epos
			end if
		end if
		fpos += 1

	end while

	-- Ensure that what we got could be a date-time value.
	if not datetime(res) then
		return -1
	end if
	
	-- Ensure no remaining digits in string.
	while spos <= length(val) do
		if types:t_digit(val[spos]) then
			return -1
		end if
		spos += 1
	end while
	
	return new(res[1], res[2], res[3], res[4], res[5], res[6])
end function

--**
-- adds a number of //intervals// to a datetime.
--
-- Parameters:
--   # ##dt## : the base datetime
--   # ##qty## : the number of //intervals// to add. It should be positive.
--   # ##interval## : which kind of interval to add.
--
-- Returns:
--   A **sequence**, more precisely a **datetime** representing the new moment in time.
--
-- Comments:
--   Please see Constants for Date and Time for a reference of valid intervals.
--
--   Do not confuse the item access constants (such as ##YEAR##, ##MONTH##, ##DAY## ) with the
--   interval constants (##YEARS##, ##MONTHS##, ##DAYS## ).
--
--   When adding ##MONTHS##, it is a calendar based addition. For instance, a date of
--   5/2/2008 with 5 ##MONTHS## added will become 10/2/2008. ##MONTHS## does not compute the number
--   of days per each month and the average number of days per month.
--
--   When adding ##YEARS##, leap year is taken into account. Adding 4 ##YEARS## to a date may result
--   in a different day of month number due to leap year.
--
-- Example 1:
-- <eucode>
-- d2 = add(d1, 35, SECONDS) -- add 35 seconds to d1
-- d2 = add(d1, 7, WEEKS)    -- add 7 weeks to d1
-- d2 = add(d1, 19, YEARS)   -- add 19 years to d1
-- </eucode>
--
-- See Also:
--     [[:subtract]], [[:diff]]

public function add(datetime dt, object qty, integer interval)
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

--**
-- subtracts a number of //intervals// to a base datetime.
--
-- Parameters:
--   # ##dt## : the base datetime
--   # ##qty## : the number of //intervals// to subtract. It should be positive.
--   # ##interval## : which kind of interval to subtract.
--
-- Returns:
--   A **sequence**, more precisely a **datetime** representing the new moment
--   in time.
--
-- Comments:
--   Please see Constants for Date and Time for a reference of valid intervals.
--
--   See the function ##add## for more information on adding and subtracting date
--   intervals
--
-- Example 1:
-- <eucode>
-- dt2 = subtract(dt1, 18, MINUTES) -- subtract 18 minutes from dt1
-- dt2 = subtract(dt1, 7, MONTHS)   -- subtract 7 months from dt1
-- dt2 = subtract(dt1, 12, HOURS)   -- subtract 12 hours from dt1
-- </eucode>
--
-- See Also:
--     [[:add]], [[:diff]]

public function subtract(datetime dt, atom qty, integer interval)
	return add(dt, -(qty), interval)
end function

--**
-- computes the difference, in seconds, between two dates.
--
-- Parameters:
--   # ##dt1## : the end datetime
--   # ##dt2## : the start datetime
--
-- Returns:
--   An **atom**, the number of seconds elapsed from ##dt2## to ##dt1##.
--
-- Comments:
--   ##dt2## is subtracted from ##dt1##, therefore, you can come up with a negative 
--   value.
--
-- Example 1:
-- <eucode>
-- d1 = now()
-- sleep(15)  -- sleep for 15 seconds
-- d2 = now()
--
-- i = diff(d1, d2) -- i is 15
-- </eucode>
--
-- See Also:
--    [[:add]], [[:subtract]]

public function diff(datetime dt1, datetime dt2)
	return datetimeToSeconds(dt2) - datetimeToSeconds(dt1)
end function
