include common.e

-- For cross-translation:
global integer TWINDOWS
global integer TDOS
global integer TLINUX
global integer TUNIX
global integer TBSD
global integer TOSX

integer ihost_platform

TWINDOWS = EWINDOWS
TDOS     = EDOS
TLINUX   = ELINUX
TUNIX    = EUNIX
TBSD     = EBSD
TOSX     = EOSX

global procedure set_host_platform( integer plat )
	ihost_platform = plat
	TUNIX    = (plat = LINUX or plat = FREEBSD)
	TWINDOWS = plat = WIN32
	TDOS     = plat = DOS32
	TBSD     = plat = FREEBSD
	TOSX     = plat = OSX
end procedure

ihost_platform = platform()
global function host_platform()
	return ihost_platform
end function
