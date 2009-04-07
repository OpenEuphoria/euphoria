--
-- Simple web server written in Euphoria
--
-- Note, this is not designed to be used in production, nor is
-- it designed to ever be completed. It is a simple example of
-- the socket routines that are part of the standard library.
--
-- Try accessing http://localhost:8080/httpd.ex or add a few
-- HTML and Image files to the current directory and access
-- those.
--
-- You can change what IP and Port are bound to for the server
-- by specifying it on the command line:
--
--   exu/exwc httpd.ex 0.0.0.0:9090
--

include std/error.e
include std/socket.e as sock
include std/text.e
include std/sequence.e
include std/io.e
include std/filesys.e
include std/map.e as m

enum LOG_FATAL, LOG_WARN, LOG_INFO, LOG_DEBUG
object
	_ = 0,
	LogLevel = LOG_INFO

m:map mime_types = m:new()

constant RESPONSE_STRING = #$
HTTP/1.0 %d
Content-Type: %s
Connection: close
Content-length: %d


$

constant ERROR_404 = #$
<html>
<head><title>404 Not Found</title></head>
<body>
<h1>404 Not Found</h1>
<p>
%s was not found on this server.
</p>
</body>
</html>
$

procedure usage_message()
	puts(1, "  Usage: httpd.ex [-bind ip_address:port] [-root document_root]\n\n")
end procedure

procedure log(integer level, sequence message, sequence values = {})
	if level <= LogLevel then
		puts(1, sprintf(message & "\n", values))
	end if
end procedure

function do_dir(sequence path, sequence doc_root)
	sequence data = sprintf("<html><head><title>%s</title></head><body><h1>%s</h1>", {
		path, path })

	data &= "<table><tr><th>Name</th><th>Size</th><th>Date</th></tr>"

	sequence files = dir(doc_root & path)
	for i = 1 to length(files) do
		if equal(files[i][D_NAME], ".") or
				(equal(path, "/") and equal(files[i][D_NAME], ".."))
		then
			continue
		end if

		if find('d', files[i][D_ATTRIBUTES]) then
			files[i][D_NAME] &= "/"
		end if

		data &= sprintf("<tr><td><a href=\"%s\">%s</a></td><td>%d</td><td>%04d-%02d-%02d %02d:%02d:%02d</td></tr>", {
			files[i][D_NAME], files[i][D_NAME], files[i][D_SIZE],
			files[i][D_YEAR], files[i][D_MONTH], files[i][D_DAY],
			files[i][D_HOUR], files[i][D_MINUTE], files[i][D_SECOND]
		})
	end for

	data &= "</table></body></html>"
	return data
end function

procedure handle_request(sock:socket server, sequence client, sequence doc_root=".")
	sock:socket client_sock = client[1]
	sequence client_addr = client[2]
	sequence request = split(trim(sock:receive(client_sock, 0)))
	sequence command = "", path = "/", version = ""

	if length(request) >= 1 then
		command = request[1]
	end if
	if length(request) >= 2 then
		path = request[2]
	end if
	if length(request) >= 3 then
		version = request[3]
	end if

	sequence fname = doc_root & path
	if fname[$] = '/' and file_exists(fname & "index.html") then
		fname &= "index.html"
	end if

	sequence data, content_type
	integer result_code

	if fname[$] = '/' then
		-- already checked for a index.html, let's give them a dir listing
		result_code = 200
		content_type = "text/html"
		data = do_dir(path, doc_root)
	elsif not file_exists(fname) then
		result_code = 404
		content_type = "text/html"
		data = sprintf(ERROR_404, { path })
	else
		result_code = 200
		content_type = m:get(mime_types, fileext(fname), "text/plain")
		data = read_file(fname)
	end if

	log(LOG_INFO, "%s %s %d %s", { client_addr, command, result_code,
		path })

	_ = sock:send(client_sock, sprintf(RESPONSE_STRING, {
		result_code, content_type, length(data)
	}), 0)
	_ = sock:send(client_sock, data, 0)
end procedure

procedure server()
	sequence args = command_line()
	sequence bind_addr = "127.0.0.1:8080", doc_root = "."

	if length(args) = 2 then
		puts(1, "NOTE: you can customise httpd.ex:\n")
		usage_message()
	end if

	for i = 3 to length(args) by 2 do
		switch args[i] do
			case "-bind" then
				bind_addr = args[i+1]

			case "-root" then
				doc_root = args[i+1]

			case else
				usage_message()
				abort(1)
		end switch
	end for

	sock:socket server = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)
	atom result = sock:bind(server, bind_addr)
	  
	if not result then
		crash("Could not bind %s, error=%d", { bind_addr, result })
	end if

	log(LOG_INFO, "Waiting for connections on %s", { bind_addr })
	while sock:listen(server, 10) do
		object client = sock:accept(server)
		if sequence(client) then
			handle_request(server, client, doc_root)
			_ = sock:close(client[1])
		end if
	end while

	_ = sock:close(server)
end procedure

sequence typs = {
	{ "htm",  "text/html" },
	{ "html", "text/html" },
	{ "css",  "text/css" },
	{ "png",  "image/png" },
	{ "jpg",  "image/jpeg" },
	{ "jpeg", "image/jpeg" }
}

for i = 1 to length(typs) do
	m:put(mime_types, typs[i][1], typs[i][2])
end for

server()
