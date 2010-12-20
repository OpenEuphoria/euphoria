--****
-- === bench/sieve8k.ex
--
-- Prime sieve benchmark "Shootout" version
--
-- ==== Usage
-- {{{
--     eui sieve8k <iterations> <largest>
-- }}}
--
-- default is 1 iteration with 8192 as largest allowable prime
--
--
-- ==== Interpreter Benchmark Results
--
-- The Euphoria interpreter seems to be the world's fastest!
-- 
-- Although it provides subscript checking, uninitialized variable checking,
-- full dynamic storage allocation, flexible generic data types,
-- and integer overflow checking, it still manages to "blow away" all other 
-- programming language interpreters that we know of.
--  
-- The results below are based on the prime sieve benchmark from the 
-- Great Computer Language Shootout by Doug Bagley. The numbers are taken 
-- from the WIN32 version of the Shootout at
--     
-- http://dada.perl.it/shootout
-- 
-- We chose sieve because it was CPU-intensive, and less trivial than some
-- of the other benchmarks. It's also integer-based, as most real programs are.
-- Naturally, you should perform your own benchmarks, based on the type of
-- programs that are important to you.
-- 
-- ==== Our Methodology:
-- 
-- We measured the speed of Euphoria on the version of sieve used in the
-- Shootout. We measured both the Euphoria interpreter, and the 
-- Euphoria To C Translator. The machine used in the WIN32 Shootout 
-- was a Pentium-4 1.6GHz running Windows XP. Our machine for the Euphoria 
-- measurements was a Pentium-4 1.8GHz, also running Windows XP. We thus 
-- adjusted our times upward by 1.8/1.6, i.e. we added 12.5%. As a check, 
-- we downloaded Python 2.1 and ran sieve with N=900 on our machine. Python 
-- was only about 3% faster on our machine, probably because CPU speed is 
-- not the only factor. Level-2 cache access time may also be important. 
-- To be fair, we nevertheless scaled up all of our Euphoria times by the 
-- full 12.5%.
-- 
-- We ran the Euphoria sieves with N=90000 to get accurate timings. For 
-- comparison, we divided by 100 to match the N=900 used on the WIN32 shootout, 
-- and we added 12.5%. 
-- 
-- The Shootout used an external timer on the programs, that necessarily
-- included start-up times. We used an internal timer in the Euphoria programs,
-- because it's more accurate, and because we lacked a good external timing 
-- mechanism. To eliminate the start-up times of the other languages,
-- we subtracted their time for N=1 from their time for N=900. In most cases
-- the N=1 start-up time was just a tiny percentage of the full N=900 time.
-- (So we were actually only timing 899 iterations for the other languages.)
--  
-- ==== The Results
-- 
-- Euphoria interpreter, eui.exe:
-- {{{
--     For N=90000 on 1.8GHz machine: 41.39 seconds
-- 
--     scaled to N=900 (divide by 100): .4139 seconds
--     
--     adjusted +12.5% to compare with 1.6 GHz: .4656
-- }}}
-- 
-- Euphoria To C Translator (with C compilation by Watcom for WIN32):
-- {{{
--     For N=90000 on 1.8GHz machine: 11.28 seconds
-- 
--     scaled to N=900 (divide by 100): .1128 seconds
--     
--     adjusted +12.5% to compare with 1.6 GHz: .1269
-- }}}
--
-- From dada.perl.it/shootout/
-- prime sieve benchmark (interpreted languages)
--
-- N=900 iterations. Start-up time (N=1) was subtracted out
-- Pentium-4 1.6 GHz
--   
-- Interpreters, sorted by seconds taken:
-- (EtoC added for comparison)
--
-- |=Lang    |=Score |=Notes                                            |
-- | Euphoria|  0.13 | EtoC Translator / Watcom                         |
-- | Euphoria|  0.47 | Interpreted with eui.exe                         |
-- | pliant  |  0.68 |                                                  |
-- | gforth  |  0.75 |                                                  |
-- | parrot  |  2.98 |                                                  |
-- | ocamlb  |  3.21 |                                                  |
-- | poplisp |  3.34 |                                                  |
-- | eu in eu|  7.15 | PD source Euphoria translated/compiled to eu.exe |
-- | erlang  |  7.16 |                                                  |
-- | lua     |  8.70 |                                                  |
-- | pike    | 10.36 |                                                  |
-- | python  | 14.33 |                                                  |
-- | icon    | 15.12 |                                                  |
-- | perl    | 16.36 |                                                  |
-- | elastic | 16.88 |                                                  |
-- | guile   | 18.64 |                                                  |
-- | cygperl | 19.22 |                                                  |
-- | ruby    | 27.59 |                                                  |
-- | mawk    | 28.00 |                                                  |
-- | vbscript| 32.02 |                                                  |
-- | php     | 67.32 |                                                  |
-- | jscript | 77.43 |                                                  |
-- | tcl     | 83.10 |                                                  |
-- | gawk    | 158.49|                                                  |
-- | rexx    | 166.85|                                                  |
--			 
-- ==== Conclusions
-- 
-- # Euphoria (interpreted) beats all of the other interpreted languages
--   in the Shootout. All of the well-known languages are beaten by a huge 
--   margin. For instance, Perl is 16.36/.4656 = 35 times slower than 
--   interpreted Euphoria. Python is 31 times slower. 
-- # If you want even greater speed, the Euphoria to C Translator can give
--   you a factor of .4656/.1269 = 3.7 versus the already-fast interpreter.
--   In fact, EtoC easily beats many compiled languages such as Java and 
--   C-Sharp (C#) on this benchmark, and it comes close to hand-coded, 
--   fully-optimized C. This is remarkable, since Euphoria code is *much*
--   easier to write and debug than C. EtoC beats both Perl and Python by
--   a factor of more than 100!
-- # Observe that even the version of Euphoria written in pure Euphoria 
--   can run twice as fast as Python or Perl which are both written in C.
--

without type_check
include std/get.e
include std/search.e
include std/console.e as con
integer SIZE = 8192, acount = 0, aiterations = 8192
sequence aflags

constant ON = 1, OFF = 0

procedure init()
	object arg
	sequence cmd
	cmd = command_line()
	if length(cmd) >= 3 then
		arg = value(cmd[3])
		if arg[1] = GET_SUCCESS then
			aiterations = arg[2]
		end if
	end if
	if length(cmd) >= 4 then
		arg = value(cmd[4])
		if arg[1] = GET_SUCCESS then
			SIZE = arg[2]

		end if
	end if
end procedure

procedure main()
	integer iterations = aiterations
	integer count
	sequence flags
	for iter = 1 to iterations do
		count = 0
		flags = repeat(ON, SIZE)
		for i = 2 to SIZE do
			if flags[i] then
				integer i2 = i + i
				for k = i2 to SIZE by i do
					flags[k] = OFF
				end for
				count += 1
			end if
		end for
	end for
	acount = count
	aflags = flags
end procedure

puts(1, "Prime Sieve Benchmark\n")

atom t
init()

t = time()  -- start timer
    
main()

t = time() - t -- end timer
printf(1, "Count: %d, Largest: %d\ntime: %g\n", {acount, rfind(ON, aflags), t})  -- 1028
con:maybe_any_key()

