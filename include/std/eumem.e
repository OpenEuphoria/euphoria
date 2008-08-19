namespace eumem

export sequence ram_space = {}
integer ram_free_list = 0

------------------------------------------
export function malloc(object count_p = 1)
------------------------------------------
	integer temp_

	if atom(count_p) then
		count_p = repeat(0, count_p)
	end if
	if ram_free_list = 0 then
		ram_space = append(ram_space, count_p)
		return length(ram_space)
	end if

	temp_ = ram_free_list
	ram_free_list = ram_space[temp_]
	ram_space[temp_] = count_p
	return temp_

end function

------------------------------------------
export procedure free(integer mem_p)
------------------------------------------
	if mem_p < 1 then return end if
	if mem_p > length(ram_space) then return end if

	ram_space[mem_p] = ram_free_list
	ram_free_list = mem_p
end procedure


------------------------------------------
export function valid(object mem_p, object count_p = 1)
------------------------------------------
	if not integer(mem_p) then return 0 end if
	if mem_p < 1 then return 0 end if
	if mem_p > length(ram_space) then return 0 end if
	
	if sequence(count_p) then return 1 end if
	
	if atom(ram_space[mem_p]) then 
		if count_p >= 0 then return 0 end if
		return 1
	end if

	if length(ram_space[mem_p]) != count_p then return 0 end if
	return 1
end function

