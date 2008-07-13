include os.e
include common.e
include platinit.e

-- For cross-translation:
global integer TWINDOWS
global integer TDOS
global integer TLINUX
global integer TUNIX
global integer TBSD
global integer TOSX
global sequence HOSTNL

integer ihost_platform

TWINDOWS = EWINDOWS
TDOS     = EDOS
TLINUX   = ELINUX
TUNIX    = EUNIX
TBSD     = EBSD
TOSX     = EOSX
if TUNIX then
	HOSTNL = "\n"
else
	HOSTNL = "\r\n"
end if

global procedure set_host_platform( atom plat )
	ihost_platform = floor(plat)
	TUNIX    = (plat = ULINUX or plat = UFREEBSD or plat = UOSX)
	TWINDOWS = plat = WIN32
	TDOS     = plat = DOS32
	TBSD     = plat = UFREEBSD
	TOSX     = plat = UOSX
	TLINUX   = plat = ULINUX
	if TUNIX then
		HOSTNL = "\n"
	else
		HOSTNL = "\r\n"
	end if
	IUNIX = TUNIX
	IWINDOWS = TWINDOWS
	IDOS = TDOS
	IBSD = TBSD
	IOSX = TOSX
	ILINUX = TLINUX
end procedure

ihost_platform = platform()
global function host_platform()
	return ihost_platform
end function
