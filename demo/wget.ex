include std/net/http.e

procedure main(sequence args = command_line())
	if length(args) = 2 then
		puts(1, "Usage: wget.ex URL\n")
		abort(1)
	end if

	sequence url = args[3]
	object data = get_url(url)

	if length(data) = 0 then
		puts(1, "Could not download " & url & "\n")
		abort(2)
	end if

	puts(1, data[1] & "\n\n")
	puts(1, data[2] & "\n")
end procedure

main()
