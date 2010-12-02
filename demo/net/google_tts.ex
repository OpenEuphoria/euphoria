#!/usr/bin/env eui
--****
-- === net/google_tts.ex
--
-- Use the Google TTS service to create an MP3 file
-- of the text given on the command line
--
-- ==== Usage
-- {{{
-- eui google_tts.ex Hello World
-- }}}
--
-- Then open in your MP3 player the resulting ##google_tts.mp3## file.
--

include std/net/http.e
include std/net/url.e
include std/sequence.e
include std/io.e

sequence cmds = command_line()
if length(cmds) < 3 then
	puts(1, "usage: google_tts.ex what to convert to mp3\n")
	abort(1)
end if

sequence u = sprintf("http://translate.google.com/translate_tts?tl=en&q=%s", {
	encode(join(cmds[3..$])) })

object r = http_get(u)
if atom(r) then
	printf(1, "Web error: %d\n", { r })
elsif length(r[2]) = 0 then
	puts(1, "Google did not translate for us.\n")
	puts(1, "They do have an unpublished 'max' character count, maybe\n")
	puts(1, "you exceeded this?\n")
else
	write_file("google_tts.mp3", r[2])
	puts(1, "MP3 stored as google_tts.mp3\n")
end if

