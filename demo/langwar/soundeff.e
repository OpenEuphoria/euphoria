-- soundeff.e: Sound Effects
include std/os.e

constant FREQ = 1, DURATION = 2

sequence sound_stream  -- sounds to be played
sound_stream = {{0,0}}

boolean playing_sound
playing_sound = FALSE

atom backlog  -- number of seconds of sounds still to play
backlog = 0

global procedure task_sound_effect()
-- process a stream of sound frequencies and durations
    atom duration, frequency

    while TRUE do
	duration  = sound_stream[1][DURATION]
	frequency = sound_stream[1][FREQ]
	if playing_sound then
	    -- we've finished the previous frequency:
	    backlog -= duration
	    sound_stream = sound_stream[2..$]
	end if
	if length(sound_stream) > 0 then
	    -- start a new frequency
	    playing_sound = TRUE
	    -- turn on the speaker
	    sound(frequency)
	    -- we'll come back later to change it,
	    -- schedule precisely:
	    task_schedule(task_self(), {duration, duration}) 
	else
	    -- nothing left to do
	    playing_sound = FALSE
	    sound(0)
	    task_suspend(task_self())
	    backlog = 0 -- otherwise f.p. "fuzz" might build up
	end if

	task_yield()
    end while
end procedure

procedure start_sound_effect()
-- start a new sound effect
    if QUIET then
	return
    end if
    if not playing_sound then
	task_schedule(t_sound_effect, {0.01, 0.02}) -- start immediately
    end if
    -- else task_sound_effect is currently processing another effect -
    -- it will continue processing the sound stream when it's ready
end procedure

global procedure errbeep()
-- error signal
    if backlog < 1 then
	sound_stream = append(sound_stream, {1000, 0.1})
	backlog += .1
	start_sound_effect()
    end if
end procedure

global procedure explosion_sound(natural n)
-- something is destroyed
    if backlog < 2 then
	for i = 1 to floor(n/3) do
	    sound_stream = append(sound_stream, {20+rand(30), .02})
	    backlog += .02
	end for
	for i = 1 to 2*n do
	    sound_stream = append(sound_stream, {200+rand(150), .01})
	    backlog += .01
	end for
	for i = 1.5*n to 3 by -1 do
	    sound_stream = append(sound_stream, {19+rand(i/2), .02})
	    backlog += .02
	end for
	start_sound_effect()
    end if
end procedure

global procedure phasor_sound(atom n)
-- phasor hits enemy with n-unit blast
    if backlog < 0.7 then
	-- 0.7 seconds, no matter what n is
	for i = 1 to 1+log(n+1) do
	    sound_stream = append(sound_stream, {1000, .025})
	    sound_stream = append(sound_stream, {3000, .025})
	    backlog += .05
	end for
	start_sound_effect()
    end if

end procedure

global procedure pod_sound(integer freq, atom duration)
-- pod in flight
    if backlog < 0.5 then
	sound_stream = append(sound_stream,{freq, duration})
	backlog += duration
	start_sound_effect()
    end if
end procedure

global procedure deflected_sound()
-- sound of a deflected torpedo
    if backlog < 0.5 then
	sound_stream = append(sound_stream, {1000, .1})
	backlog += .1
	start_sound_effect()
    end if
end procedure

global procedure torpedo_hit()
-- torpedo hits enemy
    phasor_sound(4000)
end procedure

global procedure torpedo_sound(integer freq, atom duration)
-- torpedo in flight
    if backlog < 0.2 then
	sound_stream = append(sound_stream, {freq, duration})
	backlog += duration
	start_sound_effect()
    end if
end procedure

global procedure Java_enter_sound()
-- Java enters quadrant
    if backlog < 0.5 then
	sound_stream &= {{120, .08},{240, .08}, {480, .08}, {960, .08}}
	backlog += .32
	start_sound_effect()
    end if
end procedure

global procedure Java_phasor_sound(integer freq, atom duration)
-- torpedo in flight
    if backlog < 0.5 then
	sound_stream = append(sound_stream, {freq, duration})
	backlog += duration
	start_sound_effect()
    end if
end procedure

global procedure docking_sound()
-- Euphoria successfully docks with a planet or base
    if backlog < 3 then
	for i = 1 to 3 do
	    sound_stream &= {{2000, .07}, {5000, .07}}
	    backlog += .14
	end for
	start_sound_effect()
    end if
end procedure

global procedure victory_sound()
-- sound when you win the game 
    for rep = 1 to 20 do
	for i = 1000 to 2000 by 20 do
	    sound_stream &= {{i, .01}, {2*i, .01}}
	end for
    end for
    start_sound_effect()
end procedure

