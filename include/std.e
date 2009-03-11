--
-- Platform independent includes
--

public include std/console.e
public include std/convert.e
public include std/datetime.e
public include std/dll.e
public include std/eds.e
public include std/error.e
public include std/filesys.e
public include std/get.e
public include std/graphcst.e
public include std/graphics.e
public include std/image.e
public include std/io.e
public include std/lcid.e
public include std/localeconv.e
public include std/machine.e
public include std/map.e
public include std/math.e
public include std/mouse.e
public include std/os.e
public include std/pretty.e
public include std/primes.e
public include std/regex.e
public include std/search.e
public include std/sequence.e
public include std/sets.e
public include std/socket.e
public include std/sort.e
public include std/stack.e
public include std/stats.e
public include std/task.e
public include std/text.e
public include std/types.e
public include std/unicode.e
public include std/unittest.e
public include std/wildcard.e

--
-- Platform dependent includes
--

ifdef DOS32 then
    public include std/dos/image.e
    public include std/dos/interrup.e
    public include std/dos/memory.e
    public include std/dos/pixels.e
    public include std/dos/base_mem.e

elsifdef WIN32 then
	public include std/win32/msgbox.e

elsifdef LINUX then

elsifdef FREEBSD then

elsifdef OSX then

end ifdef

--
-- Includes that require open_dll support but are otherwise platform independent
--

ifdef not DOS32 then
	public include std/locale.e
end ifdef
