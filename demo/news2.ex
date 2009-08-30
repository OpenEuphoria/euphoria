-- Search news pages


-- It's SOOO much faster than news.ex because :
--  1) i use http.e (which i also sped up).
--  2) i am therefore using no system() calls, which block.
--  3) i reduced the task schedule times for the main task to 1 sec.
--  4) being it does not use any wget, which uses files for pipes, 
--      it's not bound by the max number of open files.
--  5) i cut the number of task_*  and  text_color() calls by half.

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
include std/sequence.e -- for split()


sequence cl
sequence search_phrase

cl = command_line() -- use if running this from command line, or called from another program
                                -- cl[1] is the interpreter you use,
                                -- cl[2] is this file,
				-- cl[3] is your search term 
cl={"","","oil slick"} -- if hardcoding in a search term, but comment this line out otherwise

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
    object line
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
    
	task_yield() -- give it up to other tasks
    end while
    
    -- this point is where you can save the header and/or the webpage
    -- you'll need to write all that messy open(), puts(), close() stuff yourself
    -- At this point, 
    -- -- mytemp[1] is the header as sent by the server, you can split() etc it for munging
    -- -- mytemp[2] is the webpage, no embedded links are retrieved, that's your task
    
    mytemp = mytemp[2] -- drop the header
    mytemp = split_any(mytemp,{10,13}) -- we want sentences to play with below
        
    position(task_self()*2+2, 1)
    text_color(BRIGHT_RED)
    puts(1, "        !! Timed Out !!                        ") 
    
    line_count = 0

    for ndx= 1 to length(mytemp) do -- step thru the page, dealing with sentence by sentence
	line = mytemp[ndx] -- one line at a time, going to be slow, see news3.ex for speed
	
		if quit then
		    return -- we've been told to quit by timeout below
		end if  
	
	if match(ustring, upper(line)) then
	    hits += 1 -- found what we were searching for!
	end if
	
	line_count += 1
	position(task_self()*2+2, 1)
	text_color(BRIGHT_GREEN)
	printf(1, "         matched %d lines out of %d   ", {hits, line_count}) -- print it out in pretty colors
	task_yield()  -- see if the internet has any more data coming in for other tasks
    end for
end procedure -- and this task is DONE !



for i = 1 to length(URLs) do
    t = task_create(routine_id("search_url"), {URLs[i], search_phrase}) -- create the tasks
    task_schedule(t, 1) -- launch the tasks with 1 sec timing
end for

if text_rows(43) then end if
puts(1, "Looking for lines containing \"" & search_phrase & "\"")

time_out = time() + 45 -- global time for all urls to have arrived and been searched in

quit = 0

task_schedule(task_self(), {1, 2})  -- check this timeout loop every 1 to 2 seconds, it's not critical

-- main loop for this main parent task --
while length(task_list()) > 1 do -- are there any tasks running besides this one main task?
    task_yield() -- give them some time 
    if time() > time_out then -- are they stalled? running over the time limit?
       quit = 1 -- the flag for all tasks to report any final results and terminate    
    end if
end while
text_color(WHITE)
position(2*length(URLs)+3, 1)
puts(1, "\nAll Done.\nPress any key to exit\n")

if getc(0) then end if



