include datetime.e as d
include unittest.e

set_test_module_name("datetime.e")

sequence tmp
datetime dt1, dt2

dt1 = d:new(2008, 4, 23, 15, 38, 00)
dt2 = d:new(2008, 4, 13, 10, 20, 15)

test_equal("new() year", 2008, dt1[DT_YEAR])
test_equal("new() month",   4, dt1[DT_MONTH])
test_equal("new() day",    23, dt1[DT_DAY])
test_equal("new() hour",   15, dt1[DT_HOUR])
test_equal("new() minute", 38, dt1[DT_MINUTE])
test_equal("new() second",  0, dt1[DT_SECOND])

test_equal("dow() #1",     4, d:dow(dt1))
test_equal("dow() #2",     1, d:dow(dt2))

test_equal("diff_seconds() #1", 883065, d:diff(dt2, dt1))

test_equal("compare() same", 0, compare(dt1, dt1))
test_equal("compare() >", 1,    compare(dt1, dt2))
test_equal("compare() <", -1,   compare(dt2, dt1))

dt2 = d:add(dt1, 93155, SECONDS)
test_equal("add() SECONDS year", 2008, dt2[DT_YEAR])
test_equal("add() SECONDS month",   4, dt2[DT_MONTH])
test_equal("add() SECONDS day",    24, dt2[DT_DAY])
test_equal("add() SECONDS hour",   17, dt2[DT_HOUR])
test_equal("add() SECONDS minute", 30, dt2[DT_MINUTE])
test_equal("add() SECONDS second", 35, dt2[DT_SECOND])

dt2 = d:add(dt1, 62, MINUTES)
test_equal("add() MINUTES year", 2008, dt2[DT_YEAR])
test_equal("add() MINUTES month",   4, dt2[DT_MONTH])
test_equal("add() MINUTES day",    23, dt2[DT_DAY])
test_equal("add() MINUTES hour",   16, dt2[DT_HOUR])
test_equal("add() MINUTES minute", 40, dt2[DT_MINUTE])
test_equal("add() MINUTES second",  0, dt2[DT_SECOND])

dt2 = d:add(dt1, 10, HOURS)
test_equal("add() HOURS year", 2008, dt2[DT_YEAR])
test_equal("add() HOURS month",   4, dt2[DT_MONTH])
test_equal("add() HOURS day",    24, dt2[DT_DAY])
test_equal("add() HOURS hour",    1, dt2[DT_HOUR])
test_equal("add() HOURS minute", 38, dt2[DT_MINUTE])
test_equal("add() HOURS second",  0, dt2[DT_SECOND])

dt2 = d:add(dt1, 380, DAYS)
test_equal("add() DAYS year", 2009, dt2[DT_YEAR])
test_equal("add() DAYS month",   5, dt2[DT_MONTH])
test_equal("add() DAYS day",     8, dt2[DT_DAY])
test_equal("add() DAYS hour",   15, dt2[DT_HOUR])
test_equal("add() DAYS minute", 38, dt2[DT_MINUTE])
test_equal("add() DAYS second",  0, dt2[DT_SECOND])

dt2 = d:add(dt1, 6, WEEKS)
test_equal("add() WEEKS year", 2008, dt2[DT_YEAR])
test_equal("add() WEEKS month",   6, dt2[DT_MONTH])
test_equal("add() WEEKS day",     4, dt2[DT_DAY])
test_equal("add() WEEKS hour",   15, dt2[DT_HOUR])
test_equal("add() WEEKS minute", 38, dt2[DT_MINUTE])
test_equal("add() WEEKS second",  0, dt2[DT_SECOND])

dt2 = d:add(dt1, 6, MONTHS)
test_equal("add() MONTHS (NOT IMPL) year", 2008, dt2[DT_YEAR])
test_equal("add() MONTHS (NOT IMPL) month",  10, dt2[DT_MONTH])
test_equal("add() MONTHS (NOT IMPL) day",    22, dt2[DT_DAY])
test_equal("add() MONTHS (NOT IMPL) hour",   15, dt2[DT_HOUR])
test_equal("add() MONTHS (NOT IMPL) minute", 38, dt2[DT_MINUTE])
test_equal("add() MONTHS (NOT IMPL) second",  0, dt2[DT_SECOND])

dt2 = d:add(dt1, 11, YEARS)
test_equal("add() YEARS (NOT IMPL) year", 2019, dt2[DT_YEAR])
test_equal("add() YEARS (NOT IMPL) month",   4, dt2[DT_MONTH])
test_equal("add() YEARS (NOT IMPL) day",    23, dt2[DT_DAY])
test_equal("add() YEARS (NOT IMPL) hour",   15, dt2[DT_HOUR])
test_equal("add() YEARS (NOT IMPL) minute", 38, dt2[DT_MINUTE])
test_equal("add() YEARS (NOT IMPL) second",  0, dt2[DT_SECOND])

tmp = date()
tmp[1] = 108 -- 2008
tmp[2] = 5 -- May
tmp[3] = 15
tmp[4] = 10
tmp[5] = 20
tmp[6] = 30

dt2 = d:from_date(tmp)
test_equal("from_date() year", 2008, dt2[DT_YEAR])
test_equal("from_date() month",   5, dt2[DT_MONTH])
test_equal("from_date() day",    15, dt2[DT_DAY])
test_equal("from_date() hour",   10, dt2[DT_HOUR])
test_equal("from_date() minute", 20, dt2[DT_MINUTE])
test_equal("from_date() second", 30, dt2[DT_SECOND])

dt2 = d:now()
test_equal("now() length", 6, length(dt2))
test_equal("now() year",   1, 2008 <= dt2[DT_YEAR])
test_equal("now() month",  1, dt2[DT_MONTH] >= 1 and dt2[DT_MONTH] <= 12)
test_equal("now() day",    1, dt2[DT_DAY] >= 1 and dt2[DT_DAY] <= 31)
test_equal("now() hour",   1, dt2[DT_HOUR] >= 0 and dt2[DT_HOUR] <= 23)
test_equal("now() minute", 1, dt2[DT_MINUTE] >= 0 and dt2[DT_MINUTE] <= 59)
test_equal("now() second", 1, dt2[DT_SECOND] >= 0 and dt2[DT_SECOND] <= 59)

dt2 = d:new(1970, 1, 1, 0, 0, 0)
test_equal("to_unix() epoch", 0, d:to_unix(dt2))
test_equal("to_unix() 2008 date", 1208965080, d:to_unix(dt1))

dt2 = d:from_unix(0)
test_equal("from_unix() epoch year", 1970, dt2[DT_YEAR])
test_equal("from_unix() epoch month",   1, dt2[DT_MONTH])
test_equal("from_unix() epoch day",     1, dt2[DT_DAY])
test_equal("from_unix() epoch hour",    0, dt2[DT_HOUR])
test_equal("from_unix() epoch minute",  0, dt2[DT_MINUTE])
test_equal("from_unix() epoch second",  0, dt2[DT_SECOND])

dt2 = d:from_unix(1208965080)
test_equal("from_unix() (Apr 2008 date) year", 2008, dt2[DT_YEAR])
test_equal("from_unix() (Apr 2008 date) month",   4, dt2[DT_MONTH])
test_equal("from_unix() (Apr 2008 date) day",    23, dt2[DT_DAY])
test_equal("from_unix() (Apr 2008 date) hour",   15, dt2[DT_HOUR])
test_equal("from_unix() (Apr 2008 date) minute", 38, dt2[DT_MINUTE])
test_equal("from_unix() (Apr 2008 date) second",  0, dt2[DT_SECOND])
