--****
-- === news.ex
--
-- Search news pages
--
-- All this demo does is read several Web pages in parallel
-- and report on the number of occurrences of a word or phrase.
-- Each page is handled by a separate Euphoria task running
-- in parallel with several other tasks.
--
-- ==== Usage
-- {{{
-- eui news.ex string
-- }}}
--
-- or:
--
-- {{{
-- eui news.ex "a multi-word phrase"
-- }}}
--
-- Search is case insensitive.
--
-- This demo uses Euphoria's multitasking feature. It can run without change on all
-- platforms supported by OpenEuphoria.
--
-- A Euphoria task is assigned to each instance URL query, searching the
-- Web page text as it arrives. In this way, when a task is blocked due
-- to a delayed response from a particular server, the program can easily
-- switch to another task that is not blocked. The program quits after a
-- period of 10-15 seconds with no progress made on any page.
--

include std/console.e  -- for maybe_any_key()
include std/graphics.e -- for all the pretty screen formatting and colors
include std/io.e       -- for write_file()
include std/net/http.e -- for get_url()
include std/search.e   -- for match_all()
include std/text.e	   -- for upper()

-- news sources
constant URLs = { -- feel free to add or delete your own. They need not be news.
	"http://www.cbc.ca/news/",
	"http://www.juancole.com/",
	"http://www.abc.net.au/",
	"http://abcnews.go.com/",
	"http://www.aljazeera.com/",
	"http://www.bbc.co.uk/news/",
	"http://www.cbsnews.com/",
	"http://www.cnn.com/",
	"http://www.democracynow.org/",
	"http://www.foxnews.com/",
	"http://www.guardiannews.com/",
	"http://www.nbcnews.com/",
	"http://www.reuters.com/",
	"http://whatreallyhappened.com/",
	"http://news.yahoo.com/"
}

-- Download a web page and search if for a string
procedure search_url(sequence url, sequence search_term)
	position(task_self() * 2 + 1, 1)
	text_color(WHITE)
	printf(1, "task %2.0f: %s\n", { task_self(), url })
	text_color(BRIGHT_BLUE)
	puts(1, "        waiting for the internet...        ")
	text_color(WHITE)

	sequence mytemp = http_get(url) -- go get the url

	while equal(mytemp,"") do
		-- get_url hasn't returned yet but it has yielded to the task system.
		if quit then
			return
		end if

		-- give some time to other tasks
		task_yield()
	end while

	write_file(sprintf("newstemp%.0f.html", task_self()), mytemp[2])

	position(task_self() * 2 + 2, 1)
	text_color(BRIGHT_RED)
	puts(1, "    !! Timed Out !!                    ")

	integer line_count = 0

 	if quit then
		return -- we've been told to quit by timeout below
	end if

	object found = match_all(upper(search_term), upper(mytemp[2]))
	if sequence(found) then
		found = length(found) -- found what we were searching for!
	else
		found = 0
	end if

	line_count += 1
	position(task_self() * 2 + 2, 1)
	text_color(BRIGHT_GREEN)
	printf(1, "        found %d instances    ", { found })
end procedure

sequence search_phrase
integer quit = 0

-- global time for all URLs to have arrived and been searched.
atom time_out = time() + 45

sequence cmds = command_line()
if length(cmds) >= 3 then
	search_phrase = cmds[3]
else
	puts(1, "Usage:\n")
	puts(1, "    eui news.ex search-phrase\n")
	maybe_any_key()
	abort(1)
end if

for i = 1 to length(URLs) do
	-- Create the task
	integer t = task_create(routine_id("search_url"), { URLs[i], search_phrase })

	-- Schedule it for every one second
	task_schedule(t, 1)
end for

clear_screen()
if text_rows(43) then end if
printf(1, `Looking for lines containing "%s"`, { search_phrase })

-- the main loop for this main parent task --
-- are there still any tasks running besides this one main task?
while length(task_list()) > 1 do
	-- check the time every 1 to 2 seconds, it's not critical
	task_schedule(task_self(), { 1, 2 })
	task_yield() -- give them some time

	if time() > time_out then -- are they stalled? Running over the time limit?
	   quit = 1 -- the flag for all tasks to report any final results and terminate
	end if
end while

text_color(WHITE)
position(2*length(URLs)+3, 1)
puts(1, "\nAll Done!\n")

