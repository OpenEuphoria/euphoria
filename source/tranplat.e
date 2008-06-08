include common.e

-- For cross-translation:
global integer TWINDOWS
global integer TDOS
global integer TLINUX
global integer TUNIX
global integer TBSD

TWINDOWS = EWINDOWS
TDOS     = EDOS
TLINUX   = ELINUX
TUNIX    = EUNIX
TBSD     = EBSD

global procedure set_platform( integer plat )
	TUNIX    = (plat = LINUX or plat = FREEBSD)
	TWINDOWS = plat = WIN32
	TDOS     = plat = DOS32
	TBSD     = plat = FREEBSD
end procedure