ifdef WINDOWS then
    public include std/win32/sounds.e
elsedef
    public procedure sound()
	    -- do nothing... someday implement sound here
    end procedure
end ifdef
