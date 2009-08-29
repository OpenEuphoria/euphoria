-- news3.ex
-- Search news pages

-- Based on Jeremy's news.ex
-- It's SOOO much faster than news.ex because :
--  1) i use http.e (which i also sped up).
--  2) i am therefore using no system() calls, which block.
--  3) i reduced the task schedule times for the main task to 1 sec.
--  4) being it does not use any wget, which uses files for pipes, 
--      it's not bound by the max number of open files.
--  5) i cut the number of task_* and    text_color() calls by half.
--  6) news3.ex uses match_all(), and does not use split(),
--      and it has fewer task_yield() and _schedule() due to 
--      no looping thru sentences. So it's faster, but the display 
--      is less busy and eye-catching than news2.ex

-- All this demo does is read several Web pages in parallel 
-- and report on the number of occurences of a word or phrase.
-- Each page is handled by a separate Euphoria task running
-- in parallel with several other tasks.

-- usage:
--    exw news.exu string
-- or:
--    exw news.exu "a multi-word phrase"
-- (case insensitive search)

-- On Linux/FreeBSD use exu instead of exw.

-- This demo uses Euphoria's new multitasking feature. It can run
-- on Linux, FreeBSD, or Windows, without change.
-- It creates multiple http.e background processes, each retrieving one Web page.

-- you will want to go nearly full screen as soon as the console window pops up,
-- because of the number of urls listed below.

without warning
include std/graphics.e -- for all the pretty screen formatting and colors
include std/text.e -- for upper()
include std/net/http.e -- for get_url() 
include std/search.e -- for match_all()

sequence cl
sequence search_phrase

cl = command_line() -- use if running this from command line, or called from another program
                                -- cl[1] is the interpreter you use,
                                -- cl[2] is this file,
				-- cl[3] is your search term , it's case insensitive
cl={"","","oil slick"} -- if hardcoding in a search term, but comment this line out otherwise
                            -- remember, atm it's case insensitive

if length(cl) >= 3 then
    search_phrase = cl[3]
else
    puts(1, "Usage:\n")
    puts(1, "       exw news.exu search-phrase\n")
    if getc(0) then
    end if
    abort(1)
end if

-- news sources
sequence URLs --feel free to add, delete, your own, they need not be news
URLs = {
    "http://www.cbc.ca/news/",
    "http://www.juancole.com/",
    "http://www.abc.net.au/",
    "http://abcnews.go.com/",
    "http://english.aljazeera.net/HomePage",
    "http://news.bbc.co.uk/",
    "http://www.cbsnews.com/",
    "http://cnn.com/",
    "http://www.democracynow.org/index.pl",
    "http://www.foxnews.com/",
    "http://www.guardian.co.uk/",
    "http://www.msnbc.msn.com/",
    "http://www.reuters.com/",
    "http://www.whatreallyhappened.com/",
    "http://news.yahoo.com/"
}

integer quit, t
atom time_out

procedure search_url(sequence url, sequence string) -- this is the do-nearly-all part
-- download a Web page and search it for a string   
    integer hits
    integer line_count
    object found
    sequence mytemp, ustring
    
    position(task_self()*2+1, 1)
    text_color(WHITE)
    printf(1, "task %2.0f: %s\n", {task_self(), url})
    text_color(BRIGHT_BLUE)
    puts(1, "         waiting for the internet...    ")
    text_color(WHITE)
    
    ustring = upper(string)
    hits = 0
    
    mytemp = {} -- clear this thing
    mytemp = get_url(url) -- go get the url
    
    while equal(mytemp,"") do -- then get_url hasn't returned yet
                                           -- altho it does now have task_yield() in it
        
	if quit then
	    return
	end if
    
	task_schedule(task_self(), {1,2}) -- wait this task 1..2 sec until the internet has time to reply
	task_yield() -- give it up to other tasks
    end while
    
    -- this point is where you can save the header and/or the webpage
    -- you'll need to write all that messy open(), puts(), close() stuff yourself
    -- At this point, 
    -- -- mytemp[1] is the header as sent by the server, you can split() etc it for munging
    -- -- mytemp[2] is the webpage, no embedded links are retrieved, that's your task
    
    mytemp = mytemp[2] -- drop the header, we want to look into the webpage
       
    position(task_self()*2+2, 1)
    text_color(BRIGHT_RED)
    puts(1, "        !! Timed Out !!                        ") 
    
    line_count = 0

 	if quit then
		return -- we've been told to quit by timeout below
	end if  

	found = match_all(ustring, upper(mytemp))
	if sequence(found) then
	    hits = length(found) -- found what we were searching for!
	end if
	
	line_count += 1
	position(task_self()*2+2, 1)
	text_color(BRIGHT_GREEN)
	printf(1, "         found %d instances   ", {hits}) -- print it out in pretty colors

end procedure -- and this task is DONE ALREADY !

for i = 1 to length(URLs) do
    t = task_create(routine_id("search_url"), {URLs[i], search_phrase})
    task_schedule(t, 1)
end for

if text_rows(43) then end if
puts(1, "Looking for lines containing \"" & search_phrase & "\"")

time_out = time() + 45 -- global time for all urls to have arrived and been searched in

quit = 0

-- the main loop for this main parent task --
while length(task_list()) > 1 do -- are there still any tasks running besides this one main task?
    task_schedule(task_self(), {1, 2})  -- check the time every 1 to 2 seconds, it's not critical
    task_yield() -- give them some time 
    if time() > time_out then -- are they stalled? running over the time limit?
       quit = 1 -- the flag for all tasks to report any final results and terminate    
    end if
end while
text_color(WHITE)
position(2*length(URLs)+3, 1)
puts(1, "\nAll Done.\nPress any key to exit\n")

if getc(0) then end if



