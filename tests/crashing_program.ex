-- program designed to crash:
include std/error.e

enum type outer_planet
	SATURN=6,
	URANUS,
	NEPTUNE,
	JUPITER=5
end type


outer_planet p = URANUS
crash("Crashing")
