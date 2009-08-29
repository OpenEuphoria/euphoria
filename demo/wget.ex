include std/console.e
include std/net/http.e


procedure main(sequence args = command_line())
	if length(args) = 2 then
		puts(1, "Usage: wget.ex URL\n")
		abort(1)
	end if

	sequence url = args[3]
	object data = get_url(url)

	if atom(data) or length(data) = 0 then
	    printf(1, "Could not download %s\n", { url })
		abort(2)
	end if

	printf(1, "%s\n\n%s\n", data)

    maybe_any_key()
end procedure

main()
