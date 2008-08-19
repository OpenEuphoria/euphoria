namespace stdeumem

export sequence gMem = {}
integer gFreeList = 0

------------------------------------------
export function malloc(object pCnt = 1)
------------------------------------------
	integer lTemp

	if atom(pCnt) then
		pCnt = repeat(0, pCnt)
	end if
	if gFreeList = 0 then
		gMem = append(gMem, pCnt)
		return length(gMem)
	end if

	lTemp = gFreeList
	gFreeList = gMem[lTemp]
	gMem[lTemp] = pCnt
	return lTemp

end function

------------------------------------------
export procedure free(integer pMem)
------------------------------------------
	if pMem < 1 then return end if
	if pMem > length(gMem) then return end if

	gMem[pMem] = gFreeList
	gFreeList = pMem
end procedure

------------------------------------------
export function valid(object pMem, object pCnt = 1)
------------------------------------------
	if not integer(pMem) then return 0 end if
	if pMem < 1 then return 0 end if
	if pMem > length(gMem) then return 0 end if
	
	if sequence(pCnt) then return 1 end if
	
	if atom(gMem[pMem]) then 
		if pCnt >= 0 then return 0 end if
		return 1
	end if

	if length(gMem[pMem]) != pCnt then return 0 end if
	return 1
end function

