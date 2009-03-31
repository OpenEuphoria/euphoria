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

procedure log(integer level, sequence message, sequence values = {})
	if level <= LogLevel then
		puts(1, sprintf(message & "\n", values))
	end if
end procedure

procedure handle_request(atom server, sequence client)
	atom client_sock = client[1]
	sequence client_addr = client[2]
	sequence request = split(trim(sock:recv(client_sock, 0)))
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

	sequence fname = "." & path
	if fname[$] = '/' then
		fname &= "index.html"
	end if

	sequence data, content_type
	integer result_code

	if not file_exists(fname) then
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
	sequence bind_addr

	if length(args) < 3 then
		bind_addr = "127.0.0.1:8080"
	else
		bind_addr = args[3]
	end if

	atom server = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0),
	  result = sock:bind(server, sock:AF_INET, bind_addr)
	  
	if result != 0 then
		crash("Could not bind %s, error=%d", { bind_addr, result })
	end if

	log(LOG_INFO, "Waiting for connections on %s", { bind_addr })
	while sock:listen(server, 10) = 0 do
		object client = sock:accept(server)
		if sequence(client) then
			handle_request(server, client)
			_ = sock:close_socket(client[1])
		end if
	end while

	_ = sock:close_socket(server)
end procedure

sequence typs = {
	{ "htm",  "text/html" },
	{ "html", "text/html" },
	{ "txt",  "text/plain" },
	{ "css",  "text/css" },
	{ "png",  "image/png" },
	{ "jpg",  "image/jpeg" },
	{ "jpeg", "image/jpeg" }
}

for i = 1 to length(typs) do
	m:put(mime_types, typs[i][1], typs[i][2])
end for

server()

