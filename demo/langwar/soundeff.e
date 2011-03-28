-- soundeff.e: Sound Effects
include std/os.e
include sched.e
include sound.e

global procedure errbeep()
-- error signal
    sound(1000)
    delay(0.1)
    sound(0)
end procedure

global procedure explosion_sound()
-- something is destroyed
    for i = 5000 to 10 by -150 do
	sound(rand(i))
	delay(0.01)
    end for
    for i = 10 to 100 by 3 do
	sound(rand(i))
	delay(0.01)
    end for
    sound(0)
end procedure

global procedure phasor_sound(atom n)
-- phasor hits enemy with n-unit blast
    for i = 1 to 5 + n/200 do
	sound(1000)
	delay(0.025)
	sound(3000)
	delay(0.025)
    end for
    sound(0)
end procedure

global procedure deflected_sound()
-- sound of a deflected torpedo
    sound(1000)
    delay(.1)
    sound(0)
end procedure

global procedure torpedo_sound()
-- torpedo hits enemy
   sound(120)
   delay(0.35)
   sound(0)
end procedure

global procedure docking_sound()
-- Euphoria successfully docks with a planet or base
    for i = 1 to 3 do
	sound(2000)
	delay(0.07)
	sound(5000)
	delay(0.07)
    end for
    sound(0)
end procedure

global procedure victory_sound()
-- sound when you win the game
    for i = 1 to 25 do
	sound(1000)
	delay(0.07)
	sound(2000)
	delay(0.07)
    end for
    sound(0)
end procedure

