--
-- Simple program to make mass changes to .htx files
-- alter as necessary for your mass change.
--
-- CAUTION: make an old directory or something and
-- backup the files before running this program
-- because, it does not back anything up. If you
-- make an error in the for loop below and have
-- not saved your data, tough luck. This is a quick
-- utility only made for a short period of time for
-- those working on the docs.
--
-- TODO: This should be removed before 4.0 release as
-- it has no lasting value. Only value during the
-- document conversion.
--

include file.e
include misc.e
include sequence.e

object ign
sequence files, data
files = dir("*.htx")

for i = 1 to length(files) do
    data = read_file(files[i][1])
    data = find_replace("_eucode>", "eucode>", data, 0)
    ign = write_file(files[i][1], data)
end for

