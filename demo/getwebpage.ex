-- This is an example of the basic way to get a webpage
--
-- It will display the header and the webpage body, as recieved from the server.
-- This does NOT get the ENTIRE page as displayed in a browser,
-- normally the browser also gets the css page, numerous js pages, images, etc.
--
-- you can use this to test your server, or just to get a favorite webpage.
--
-- header may be useful for debugging,
-- webpage is what you'd see in the browser window, once the html is executed and other stuff is recieved.
--

with trace
include std/net/http.e
include get.e
include misc.e

sequence data, header, webpage

data = get_url("http://news.bbc.co.uk/2/low/south_asia/5409358.stm")
if sequence(data) 
  then -- it's a webpage! maybe...
      header = data[1] -- header , the way the server sent them
      webpage = data[2] -- this is what the browser shows you
      puts(1,"\nThe header sent to us is:\n")
      puts(1,header)
      puts(1,"\n\npress any key to continue.")
      if wait_key() then end if
      puts(1,"\nThe webpage sent to us is:\n")
      puts(1,webpage)
  else  -- must be some sorta error?  The internet isn't perfect, ya know.
      webpage = data -- you'll haveto look into this yourself and see what the problem was
end if  



puts(1,"\n\npress any key to end")
if wait_key() then end if
