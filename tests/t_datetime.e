include datetime.e
include unittest.e

set_test_module_name("datetime.e")

sequence tmp
datetime dt1, dt2

dt1 = datetime_new(2008, 4, 23, 15, 38, 00)
dt2 = datetime_new(2008, 4, 13, 10, 20, 15)

test_equal("datetime_new() year", 2008, dt1[DT_YEAR])
test_equal("datetime_new() month",   4, dt1[DT_MONTH])
test_equal("datetime_new() day",    23, dt1[DT_DAY])
test_equal("datetime_new() hour",   15, dt1[DT_HOUR])
test_equal("datetime_new() minute", 38, dt1[DT_MINUTE])
test_equal("datetime_new() second",  0, dt1[DT_SECOND])

test_equal("datetime_dow() #1",     4, datetime_dow(dt1))
test_equal("datetime_dow() #2",     1, datetime_dow(dt2))

test_equal("datetime_diff_days() #1", 10, datetime_diff_days(dt2, dt1))
test_equal("datetime_diff_seconds() #1", 883065, datetime_diff_seconds(dt2, dt1))

test_equal("datetime_compare() same", 0, datetime_compare(dt1, dt1))
test_equal("datetime_compare() >", 1,    datetime_compare(dt1, dt2))
test_equal("datetime_compare() <", -1,   datetime_compare(dt2, dt1))

dt2 = datetime_add_days(dt1, 380)
test_equal("datetime_add_days() year", 2009, dt2[DT_YEAR])
test_equal("datetime_add_days() month",   5, dt2[DT_MONTH])
test_equal("datetime_add_days() day",     8, dt2[DT_DAY])

dt2 = datetime_add_seconds(dt1, 93155)
test_equal("datetime_add_seconds() year", 2008, dt2[DT_YEAR])
test_equal("datetime_add_seconds() month",   4, dt2[DT_MONTH])
test_equal("datetime_add_seconds() day",    24, dt2[DT_DAY])
test_equal("datetime_add_seconds() hour",   17, dt2[DT_HOUR])
test_equal("datetime_add_seconds() minute", 30, dt2[DT_MINUTE])
test_equal("datetime_add_seconds() second", 35, dt2[DT_SECOND])

tmp = date()
tmp[1] = 108 -- 2008
tmp[2] = 5 -- May
tmp[3] = 15
tmp[4] = 10
tmp[5] = 20
tmp[6] = 30

dt2 = datetime_from_date(tmp)
test_equal("datetime_from_date() year", 2008, dt2[DT_YEAR])
test_equal("datetime_from_date() month",   5, dt2[DT_MONTH])
test_equal("datetime_from_date() day",    15, dt2[DT_DAY])
test_equal("datetime_from_date() hour",   10, dt2[DT_HOUR])
test_equal("datetime_from_date() minute", 20, dt2[DT_MINUTE])
test_equal("datetime_from_date() second", 30, dt2[DT_SECOND])

dt2 = datetime_now()
test_equal("datetime_now() length", 6, length(dt2))
test_equal("datetime_now() year",   1, 2008 <= dt2[DT_YEAR])
test_equal("datetime_now() month",  1, dt2[DT_MONTH] >= 1 and dt2[DT_MONTH] <= 12)
test_equal("datetime_now() day",    1, dt2[DT_DAY] >= 1 and dt2[DT_DAY] <= 31)
test_equal("datetime_now() hour",   1, dt2[DT_HOUR] >= 0 and dt2[DT_HOUR] <= 23)
test_equal("datetime_now() minute", 1, dt2[DT_MINUTE] >= 0 and dt2[DT_MINUTE] <= 59)
test_equal("datetime_now() second", 1, dt2[DT_SECOND] >= 0 and dt2[DT_SECOND] <= 59)

dt2 = datetime_new(1970, 1, 1, 0, 0, 0)
test_equal("datetime_to_unix() epoch", 0, datetime_to_unix(dt2))
test_equal("datetime_to_unix() 2008 date", 1208965080, datetime_to_unix(dt1))

dt2 = datetime_from_unix(0)
test_equal("datetime_from_unix() epoch year", 1970, dt2[DT_YEAR])
test_equal("datetime_from_unix() epoch month",   1, dt2[DT_MONTH])
test_equal("datetime_from_unix() epoch day",     1, dt2[DT_DAY])
test_equal("datetime_from_unix() epoch hour",    0, dt2[DT_HOUR])
test_equal("datetime_from_unix() epoch minute",  0, dt2[DT_MINUTE])
test_equal("datetime_from_unix() epoch second",  0, dt2[DT_SECOND])

dt2 = datetime_from_unix(1208965080)
test_equal("datetime_from_unix (Apr 2008 date) year", 2008, dt2[DT_YEAR])
test_equal("datetime_from_unix (Apr 2008 date) month",   4, dt2[DT_MONTH])
test_equal("datetime_from_unix (Apr 2008 date) day",    23, dt2[DT_DAY])
test_equal("datetime_from_unix (Apr 2008 date) hour",   15, dt2[DT_HOUR])
test_equal("datetime_from_unix (Apr 2008 date) minute", 38, dt2[DT_MINUTE])
test_equal("datetime_from_unix (Apr 2008 date) second",  0, dt2[DT_SECOND])
