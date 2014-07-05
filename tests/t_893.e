include std/map.e 
include std/console.e 
include std/unittest.e


map gimlet = load_map( "893.map" )
map foo = map:new() 
 
map:put( foo, `:=`, `assignment` ) 
map:put( foo, `==`, `comparison` ) 
map:put( foo, `,$`, `placeholder` ) 
map:put( foo, `, $`, `erroneous - no spaces` ) 
map:put( foo, `--`, `comment ---- to end of line` ) 
 
map:save_map( foo, "foo.map" )

sequence key_set = map:keys( foo )
for i = 1 to length(key_set) do
    sequence key = key_set[i] 
    if map:has( gimlet, key) then
        test_equal(  "ticket 893: " & key, map:get( foo, key ), map:get( gimlet, key )  )
    else
        test_fail(  "ticket 893: " & key )
    end if
end for

test_report()
