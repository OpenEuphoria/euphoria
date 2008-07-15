include std/datetime.e as d
include std/unittest.e

sequence tmp
datetime dt1, dt2

dt1 = d:new()
dt2 = d:now()
test_equal("new() ", dt1, dt2)

dt1 = d:new_time(18, 53, 14.5)
test_equal("new_time() ", {0,0,0,18,53,14.5}, dt1)

dt1 = d:new(2008, 4, 23, 15, 38, 00)
dt2 = d:new(2008, 4, 13, 10, 20, 15)

test_equal("new() year", 2008, dt1[YEAR])
test_equal("new() month",   4, dt1[MONTH])
test_equal("new() day",    23, dt1[DAY])
test_equal("new() hour",   15, dt1[HOUR])
test_equal("new() minute", 38, dt1[MINUTE])
test_equal("new() second",  0, dt1[SECOND])

test_equal("dow() #1", 4, d:dow(dt1))
test_equal("dow() #2", 1, d:dow(dt2))

test_equal("doy() #1", 114, d:doy(dt1))

test_equal("diff_seconds() #1", 883065, d:diff(dt2, dt1))

test_equal("compare() same", 0, compare(dt1, dt1))
test_equal("compare() >", 1,    compare(dt1, dt2))
test_equal("compare() <", -1,   compare(dt2, dt1))

dt2 = d:add(dt1, 93155, SECONDS)
test_equal("add() SECONDS year", 2008, dt2[YEAR])
test_equal("add() SECONDS month",   4, dt2[MONTH])
test_equal("add() SECONDS day",    24, dt2[DAY])
test_equal("add() SECONDS hour",   17, dt2[HOUR])
test_equal("add() SECONDS minute", 30, dt2[MINUTE])
test_equal("add() SECONDS second", 35, dt2[SECOND])

dt2 = d:add(dt1, 62, MINUTES)
test_equal("add() MINUTES year", 2008, dt2[YEAR])
test_equal("add() MINUTES month",   4, dt2[MONTH])
test_equal("add() MINUTES day",    23, dt2[DAY])
test_equal("add() MINUTES hour",   16, dt2[HOUR])
test_equal("add() MINUTES minute", 40, dt2[MINUTE])
test_equal("add() MINUTES second",  0, dt2[SECOND])

dt2 = d:add(dt1, 10, HOURS)
test_equal("add() HOURS year", 2008, dt2[YEAR])
test_equal("add() HOURS month",   4, dt2[MONTH])
test_equal("add() HOURS day",    24, dt2[DAY])
test_equal("add() HOURS hour",    1, dt2[HOUR])
test_equal("add() HOURS minute", 38, dt2[MINUTE])
test_equal("add() HOURS second",  0, dt2[SECOND])

dt2 = d:add(dt1, 380, DAYS)
test_equal("add() DAYS year", 2009, dt2[YEAR])
test_equal("add() DAYS month",   5, dt2[MONTH])
test_equal("add() DAYS day",     8, dt2[DAY])
test_equal("add() DAYS hour",   15, dt2[HOUR])
test_equal("add() DAYS minute", 38, dt2[MINUTE])
test_equal("add() DAYS second",  0, dt2[SECOND])

dt2 = d:add(dt1, 6, WEEKS)
test_equal("add() WEEKS year", 2008, dt2[YEAR])
test_equal("add() WEEKS month",   6, dt2[MONTH])
test_equal("add() WEEKS day",     4, dt2[DAY])
test_equal("add() WEEKS hour",   15, dt2[HOUR])
test_equal("add() WEEKS minute", 38, dt2[MINUTE])
test_equal("add() WEEKS second",  0, dt2[SECOND])

dt2 = d:add(dt1, 6, MONTHS)
test_equal("add() MONTHS year", 2008, dt2[YEAR])
test_equal("add() MONTHS month",  10, dt2[MONTH])
test_equal("add() MONTHS day",    23, dt2[DAY])
test_equal("add() MONTHS hour",   15, dt2[HOUR])
test_equal("add() MONTHS minute", 38, dt2[MINUTE])
test_equal("add() MONTHS second",  0, dt2[SECOND])

dt2 = d:add(dt1, 14, MONTHS)
test_equal("add() MONTHS #2 year", 2009, dt2[YEAR])
test_equal("add() MONTHS #2 month",   6, dt2[MONTH])
test_equal("add() MONTHS #2 day",    23, dt2[DAY])
test_equal("add() MONTHS #2 hour",   15, dt2[HOUR])
test_equal("add() MONTHS #2 minute", 38, dt2[MINUTE])
test_equal("add() MONTHS #2 second",  0, dt2[SECOND])

dt2 = d:add(dt1, 11, YEARS)
test_equal("add() YEARS (NOT IMPL) year", 2019, dt2[YEAR])
test_equal("add() YEARS (NOT IMPL) month",   4, dt2[MONTH])
test_equal("add() YEARS (NOT IMPL) day",    23, dt2[DAY])
test_equal("add() YEARS (NOT IMPL) hour",   15, dt2[HOUR])
test_equal("add() YEARS (NOT IMPL) minute", 38, dt2[MINUTE])
test_equal("add() YEARS (NOT IMPL) second",  0, dt2[SECOND])

dt2 = d:subtract(dt1, 2, DAYS)
test_equal("subtract() SECONDS year", 2008, dt2[YEAR])
test_equal("subtract() SECONDS month",   4, dt2[MONTH])
test_equal("subtract() SECONDS day",    21, dt2[DAY])
test_equal("subtract() SECONDS hour",   15, dt2[HOUR])
test_equal("subtract() SECONDS minute", 38, dt2[MINUTE])
test_equal("subtract() SECONDS second",  0, dt2[SECOND])

dt2 = d:subtract(dt1, 6, MONTHS)
test_equal("subtract() MONTHS year", 2007, dt2[YEAR])
test_equal("subtract() MONTHS month",  10, dt2[MONTH])
test_equal("subtract() MONTHS day",    23, dt2[DAY])
test_equal("subtract() MONTHS hour",   15, dt2[HOUR])
test_equal("subtract() MONTHS minute", 38, dt2[MINUTE])
test_equal("subtract() MONTHS second",  0, dt2[SECOND])

dt2 = d:subtract(dt1, 9, YEARS)
test_equal("subtract() YEARS year", 1999, dt2[YEAR])
test_equal("subtract() YEARS month",   4, dt2[MONTH])
test_equal("subtract() YEARS day",    23, dt2[DAY])
test_equal("subtract() YEARS hour",   15, dt2[HOUR])
test_equal("subtract() YEARS minute", 38, dt2[MINUTE])
test_equal("subtract() YEARS second",  0, dt2[SECOND])

tmp = date()
tmp[1] = 108 -- 2008
tmp[2] = 5 -- May
tmp[3] = 15
tmp[4] = 10
tmp[5] = 20
tmp[6] = 30

dt2 = d:from_date(tmp)
test_equal("from_date() year", 2008, dt2[YEAR])
test_equal("from_date() month",   5, dt2[MONTH])
test_equal("from_date() day",    15, dt2[DAY])
test_equal("from_date() hour",   10, dt2[HOUR])
test_equal("from_date() minute", 20, dt2[MINUTE])
test_equal("from_date() second", 30, dt2[SECOND])

dt2 = d:now()
test_equal("now() length", 6, length(dt2))
test_equal("now() year",   1, 2008 <= dt2[YEAR])
test_equal("now() month",  1, dt2[MONTH] >= 1 and dt2[MONTH] <= 12)
test_equal("now() day",    1, dt2[DAY] >= 1 and dt2[DAY] <= 31)
test_equal("now() hour",   1, dt2[HOUR] >= 0 and dt2[HOUR] <= 23)
test_equal("now() minute", 1, dt2[MINUTE] >= 0 and dt2[MINUTE] <= 59)
test_equal("now() second", 1, dt2[SECOND] >= 0 and dt2[SECOND] <= 59)

dt2 = d:new(1970, 1, 1, 0, 0, 0)
test_equal("to_unix() epoch", 0, d:to_unix(dt2))
test_equal("to_unix() 2008 date", 1208965080, d:to_unix(dt1))

dt2 = d:from_unix(0)
test_equal("from_unix() epoch year", 1970, dt2[YEAR])
test_equal("from_unix() epoch month",   1, dt2[MONTH])
test_equal("from_unix() epoch day",     1, dt2[DAY])
test_equal("from_unix() epoch hour",    0, dt2[HOUR])
test_equal("from_unix() epoch minute",  0, dt2[MINUTE])
test_equal("from_unix() epoch second",  0, dt2[SECOND])

dt2 = d:from_unix(1208965080)
test_equal("from_unix() (Apr 2008 date) year", 2008, dt2[YEAR])
test_equal("from_unix() (Apr 2008 date) month",   4, dt2[MONTH])
test_equal("from_unix() (Apr 2008 date) day",    23, dt2[DAY])
test_equal("from_unix() (Apr 2008 date) hour",   15, dt2[HOUR])
test_equal("from_unix() (Apr 2008 date) minute", 38, dt2[MINUTE])
test_equal("from_unix() (Apr 2008 date) second",  0, dt2[SECOND])

dt1 = d:new(2008, 4, 23, 15, 38, 00)
test_equal("format() simple m/d/Y H:M:S", "04/23/2008 15:38:00pm", d:format(dt1, "%m/%d/%Y %H:%M:%S%P"))
test_equal("format() %%", "%", d:format(dt1, "%%"))
test_equal("format() %a", "Wed", d:format(dt1, "%a"))
test_equal("format() %A", "Wednesday", d:format(dt1, "%A"))
test_equal("format() %b", "Apr", d:format(dt1, "%b"))
test_equal("format() %B", "April", d:format(dt1, "%B"))
test_equal("format() %C", "20", d:format(dt1, "%C"))
test_equal("format() %d", "23", d:format(dt1, "%d"))
test_equal("format() %H", "15", d:format(dt1, "%H"))
test_equal("format() %I", "03", d:format(dt1, "%I"))
test_equal("format() %j", "114", d:format(dt1, "%j"))
test_equal("format() %k", "15", d:format(dt1, "%k"))
test_equal("format() %l", "3", d:format(dt1, "%l"))
test_equal("format() %m", "04", d:format(dt1, "%m"))
test_equal("format() %M", "38", d:format(dt1, "%M"))
test_equal("format() %p", "PM", d:format(dt1, "%p"))
test_equal("format() %P", "pm", d:format(dt1, "%P"))
test_equal("format() %s", "1208965080", d:format(dt1, "%s"))
test_equal("format() %S", "00", d:format(dt1, "%S"))
test_equal("format() %u", "3", d:format(dt1, "%u"))
test_equal("format() %w", "3", d:format(dt1, "%w"))
test_equal("format() %y", "08", d:format(dt1, "%y"))
test_equal("format() %Y", "2008", d:format(dt1, "%Y"))

for i = 1 to 7 do
    dt1[DAY] = i + 19
    test_equal("format() dow loop #1", day_abbrs[i], d:format(dt1, "%a"))
    test_equal("format() dow loop #2", day_names[i], d:format(dt1, "%A"))
end for

for i = 0 to 11 do
    dt1[MONTH] = i+1
    dt1[HOUR] = i
    test_equal("format() month loop #1", month_abbrs[i+1], d:format(dt1, "%b"))
    test_equal("format() month loop #2", month_names[i+1], d:format(dt1, "%B"))

    test_equal("format() hour loop #1", sprintf("%02d", i), d:format(dt1, "%H"))
	if i > 0 then -- AM/PM swap on 0
	    test_equal("format() hour loop #2", sprintf("%02damAM", i), d:format(dt1, "%I%P%p"))
	end if

    dt1[HOUR] = i + 12
    test_equal("format() hour loop #3", sprintf("%02d", i + 12), d:format(dt1, "%H"))
	if i > 0 then -- AM/PM swap on 0
	    test_equal("format() hour loop #4", sprintf("%dpmPM", i), d:format(dt1, "%l%P%p"))
	end if
end for

test_report()

