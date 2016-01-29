--****
-- === net/wget.ex
--
-- WGet clone, a URL downloaded.
--
-- ==== Usage
--
-- {{{
-- eui wget http://openeuphoria.org
-- }}}
--

include std/console.e
include std/net/http.e
without warning

--**
-- @nodoc@
override procedure abort(integer x)
	maybe_any_key()
	eu:abort(x)
end procedure

procedure main(sequence args = command_line())
	if length(args) = 2 then
		ifdef WINDOWS and GUI then
		    puts(1, "This program must be run from the command-line:\n\n")
		end ifdef
		puts(1, "Usage: eui wget.ex URL\n")
		abort(1)
	end if

	sequence url = args[3]
	object data = http_get(url)

	if atom(data) or length(data) = 0 then
		printf(1, "Could not download %s\n", { url })
		abort(2)
	end if

	printf(1, "%s\n", { data[2] })
end procedure

main()
