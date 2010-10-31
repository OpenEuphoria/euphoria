include std/unittest.e

ifdef UNIX then

include std/unix/mmap.e
include std/machine.e
include std/filesys.e

test_report()

end ifdef
