	-----------------------------------------------
	-- A Quiz to Test Your Knowledge of Euphoria --
	-----------------------------------------------
include get.e
include graphics.e

constant NTRYS = 3
constant KEYBOARD = 0, SCREEN = 1

procedure get_answer(object correct)
    sequence answer
    atom t
    integer c
    
    for i = 1 to NTRYS do
	answer = get(KEYBOARD)
	puts(SCREEN, '\n')
	if answer[1] = GET_SUCCESS then
	    if equal(answer[2], correct) then
		puts(SCREEN, "Correct!\n\n")
		sound(2000)
		t = time()
		while time() < t+0.1 do
		end while
		sound(0)
		return
	    elsif i < NTRYS then
		puts(SCREEN, "Try again\n")
		sound(200)
		t = time()
		while time() < t+0.4 do
		end while
		sound(0)
	    end if
	else
	    puts(SCREEN, "syntax error - a Euphoria object is expected\n")
	    -- clear rest of line:
	    for j = 1 to 100 do
		c = getc(KEYBOARD)
		if c = -1 then
		    abort(0)
		elsif c = '\n' then
		    exit
		end if
	    end for 
	end if    
    end for
    puts(SCREEN, "The correct answer was: ")
    print(SCREEN, correct)
    puts(SCREEN, '\n')
end procedure

procedure part1()
-- evaluating simple expressions
    object x, y

    puts(SCREEN, "Please evaluate the following Euphoria expressions\n")
    puts(SCREEN, "You have 3 guesses.\n\n")

    x = rand(10)
    y = rand(10)
    printf(SCREEN, "%d + %d\n", {x, y})
    get_answer(x + y)

    x = rand(repeat(10, 3))
    y = rand(10)
    print(SCREEN, x)
    puts(SCREEN, " * ")
    print(SCREEN, y)
    puts(SCREEN, '\n')
    get_answer(x * y)

    x = rand(repeat(10, 4)) - 5
    y = rand(repeat(10, 4)) - 5
    print(SCREEN, x)
    puts(SCREEN, " > ")
    print(SCREEN, y)
    puts(SCREEN, '\n')
    get_answer(x > y)    

    x = rand(20)
    y = rand(5)
    puts(SCREEN, "repeat(")
    print(1, x)
    puts(SCREEN, ", ")
    print(1, y)
    puts(SCREEN, ")\n")
    get_answer(repeat(x, y))
    
    x = rand(repeat(25, 3)) + 'a'
    y = rand(repeat(25, 2)) + 'a'
    printf(SCREEN, "\"%s\" & \"%s\"\n", {x, y})
    get_answer(x & y)

    x = rand(repeat(99,3))
    y = rand(repeat(99,2))
    puts(SCREEN, "append(")
    print(SCREEN, x)
    puts(SCREEN, ", ")
    print(SCREEN, y)
    puts(SCREEN, ")\n")
    get_answer(append(x, y))
    
    puts(SCREEN, "what will the value of x be\n")
    puts(SCREEN, "after executing the following statements?\n")
    puts(SCREEN, "x = ")
    x = rand({10, 10, {10, 10, 10, 10}, 20})
    print(SCREEN, x)
    y = rand({20, 20, 20, 20, 20})
    puts(SCREEN, "\ny = ")
    print(SCREEN, y)
    puts(SCREEN, "\nx[3][2..3] = y[4..5]\n")    
    x[3][2..3] = y[4..5]
    get_answer(x)
end procedure

part1()   -- quick questions

