ifdef WINDOWS then
    public include std/win32/sounds.e
elsedef
    public procedure sound( atom sound_type = 0 )
	    -- do nothing... someday implement sound here
    end procedure
end ifdef
