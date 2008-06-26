 -- The value of platform_names should be the equivalent of the perl hash: 
-- { DOS32 => { "DOS" }, WIN32 => { "WIN" },  
-- LINUX(=FREEBSD=UNIX) =>{ "UNIX", "LINUX", "FREEBSD" },  
-- OSX => { "OSX" } } 

include unittest.e
include map.e as hash
include os.e as os

constant platform_names = 
		--hash:put(  
	        hash:put( 
	        hash:put( 
	        hash:put( 
	        hash:put( 
	--      hash:put(  
	        hash:put( hash:put( hash:put( hash:put( 
	        put( hash:new( 10 ), 
	        os:DOS32, {}, ), 
	        os:WIN32, {}, ), 
	        os:LINUX, {}, ), 
	        os:FREEBSD, {}, ), 
	--      os:OSX, {}, ),  
	        DOS32,  "DOS32" , 100, hash:APPEND ), 
	        os:WIN32,  "WIN32" , 100, hash:APPEND ), 
	        os:LINUX, "LINUX", 100, hash:APPEND ), 
	        os:LINUX,    "UNIX", 100, hash:APPEND ), 
	        os:FREEBSD,  "FREEBSD" , 100, hash:APPEND ) 
	--      os:OSX,  "OSX" , 100, hash:APPEND ) 

constant platform_values = 
	--hash:put(  
	hash:put( hash:put( hash:put( 
	hash:put( hash:put( hash:new(), 
	"DOS32", os:DOS32 ), 
	"WIN32", os:WIN32 ), 
	"LINUX", os:LINUX ), 
	"FREEBSD", os:FREEBSD ), 
	"UNIX", os:LINUX ) 
	--"OSX",  os:OSX ) 

constant compile_flags = 
	hash:put( hash:put( hash:put( hash:put( 
	hash:put( hash:put( hash:new(), 
	"DOS32", "-WAT " ), 
	"WIN32", "-WAT -CON " ), 
	"LINUX", "" ), 
	"FREEBSD", "" ), 
	"UNIX", "" ), 
	"OSX",  "" ) 

constant translator_names = 
	hash:put( hash:put( hash:put( hash:put( 
	hash:put( hash:put( hash:new(), 
	"DOS32", "ec " ), 
	"WIN32", "ecw " ), 
	"LINUX", "ecu" ), 
	"FREEBSD", "ecu" ), 
	"UNIX", "ecu" ), 
	"OSX",  "ecu" ) 

test_true("Created the Hashes:", 1) 

test_embedded_report()
