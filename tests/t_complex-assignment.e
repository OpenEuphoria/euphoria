 -- The value of platform_names should be the equivalent of the perl stdmap: 
-- { DOS32 => { "DOS" }, WIN32 => { "WIN" },  
-- LINUX(=FREEBSD=UNIX) =>{ "UNIX", "LINUX", "FREEBSD" },  
-- OSX => { "OSX" } } 

include std/unittest.e
include std/map.e
include std/os.e as os

function putm(map m, object k, object v, integer trigger = 100, object act = stdmap:PUT)
	stdmap:put(m, k, v, trigger, act)
	return m
end function

constant platform_names = 
		putm(  
	        putm( 
		        putm( 
		        	putm( 
	    	    		putm( 
	        				putm( 
						      putm(  
	        						putm( 
        								putm( 
        									putm( 
        										putm( stdmap:new( 12 ), 
        											os:DOS32, {}, ), 
        										os:WIN32, {}, ), 
        									os:LINUX, {}, ), 
	        							os:FREEBSD, {}, ), 
							      os:OSX, {}, ),  
	    	    				os:DOS32,  "DOS32" , 100, stdmap:APPEND ), 
	        				os:WIN32,  "WIN32" , 100, stdmap:APPEND ), 
	        			os:LINUX, "LINUX", 100, stdmap:APPEND ), 
	        		os:LINUX,    "UNIX", 100, stdmap:APPEND ), 
	        	os:FREEBSD,  "FREEBSD" , 100, stdmap:APPEND ), 
	      os:OSX,  "OSX" , 100, stdmap:APPEND ) 

constant platform_values = 
	putm(  
		putm( 
			putm( 
				putm( 
					putm( 
						putm( stdmap:new(10), 
							"DOS32", os:DOS32 ), 
						"WIN32", os:WIN32 ), 
					"LINUX", os:LINUX ), 
				"FREEBSD", os:FREEBSD ), 
			"UNIX", os:LINUX ), 
	"OSX",  os:OSX ) 

constant compile_flags = 
	putm( 
		putm( 
			putm( 
				putm( 
					putm( 
						putm( stdmap:new(10), 
							"DOS32", "-WAT " ), 
						"WIN32", "-WAT -CON " ), 
					"LINUX", "" ), 
				"FREEBSD", "" ), 
			"UNIX", "" ), 
		"OSX",  "" ) 

constant translator_names = 
	putm( 
		putm( 
			putm( 
				putm( 
					putm( 
						putm( stdmap:new(10), 
							"DOS32", "ec " ), 
						"WIN32", "ecw " ), 
					"LINUX", "ecu" ), 
				"FREEBSD", "ecu" ), 
			"UNIX", "ecu" ), 
		"OSX",  "ecu" ) 

test_true("Created the Hashes:", 1) 

test_report()
