--****
-- == Euphoria Information
--
-- <<LEVELTOC level=2 depth=4>>

namespace info

constant M_EU_INFO=75

enum MAJ_VER, MIN_VER, PAT_VER, VER_TYPE, NODE, REVISION, REVISION_DATE, START_TIME

include std/dll.e
include std/machine.e

constant version_info = machine_func(M_EU_INFO, {})

--****
-- === Build Type Constants
--

--**
-- Is this build a developmental build?
--

public constant is_developmental = equal(version_info[VER_TYPE], "development")

--**
-- Is this build a release build?
--

public constant is_release = (is_developmental = 0)

--****
-- === Numeric Version Information
--

--****
-- === Compiled Platform Information

--**
-- Get the platform name
--
-- Returns:
--   A **sequence**, containing the platform name, i.e. Windows, Linux, FreeBSD or OS X.
--

public function platform_name()
	ifdef WINDOWS then
		return "Windows"
	elsifdef LINUX then
		return "Linux"
	elsifdef OSX then
		return "OS X"
	elsifdef FREEBSD then
		return "FreeBSD"
	elsifdef OPENBSD then
		return "OpenBSD"
	elsifdef NETBSD then
		return "NetBSD"
	elsedef
		return "Unknown"
	end ifdef
end function

--**
-- Get the native architecture word size.
--
-- Returns:
--   A **sequence** in the form of "%d-bit", where %d is the word size for the
--   architecture for which this version of euphoria was built.
public function arch_bits()
	return sprintf( "%d-bit", 8 * sizeof( C_POINTER ) )
end function


--**
-- Get the version, as an integer, of the host Euphoria
--
-- Returns:
--   An **integer**, representing Major, Minor and Patch versions. Version
--   4.0.0 will return 40000, 4.0.1 will return 40001,
--   5.6.2 will return 50602, 5.12.24 will return 512624, etc...
--

public function version()
	return (version_info[MAJ_VER] * 10000) +
		(version_info[MIN_VER] * 100) + 
		version_info[PAT_VER]
end function

--**
-- Get the major version of the host Euphoria
--
-- Returns:
--   An **integer**, representing the Major version number. Version 4.0.0 will
--   return 4, version 5.6.2 will return 5, etc...
--

public function version_major()
	return version_info[MAJ_VER]
end function

--**
-- Get the minor version of the hosting Euphoria
--
-- Returns:
--   An **integer**, representing the Minor version number. Version 4.0.0
--   will return 0, 4.1.0 will return 1, 5.6.2 will return 6, etc...
--

public function version_minor()
	return version_info[MIN_VER]
end function

--**
-- Get the patch version of the hosting Euphoria
--
-- Returns:
--   An **integer**, representing the Path version number. Version 4.0.0
--   will return 0, 4.0.1 will return 1, 5.6.2 will return 2, etc...
--

public function version_patch()
	return version_info[PAT_VER]
end function

--**
-- Get the source code node id of the hosting Euphoria
--
-- Parameters:
--   * ##full## - If TRUE, the full node id is returned. If FALSE
--     only the first ##n## characters of the node id is returned.
--     Typically the short node id is considered unique.
--   * ##n## - Maximum number of characters to return.
--
-- Returns:
--   A text **sequence**, containing the source code management systems
--   node id that globally identifies the executing Euphoria.
--

public function version_node(integer full = 0, integer n = 12)
	if full or length(version_info[NODE]) < n then
		return version_info[NODE]
	end if

	return version_info[NODE][1..n]
end function

--**
-- Get the source code revision of the hosting Euphoria
--
-- Returns:
--   A text **sequence**, containing the source code management systems
--   revision number that the executing Euphoria was built from.
--

public function version_revision()
	return version_info[REVISION]
end function

--**
-- Get the compilation date of the hosting Euphoria
--
-- Parameters:
--   * ##full## - Standard return value is a string formatted as ##CCYY-MM-DD##. However,
--     if this is a development build or the ##full## parameter is TRUE (1), then
--     the result will be formatted as ##CCYY-MM-DD HH:MM:SS##.
--
-- Returns:
--   A text **sequence** containing the commit date of the
--   the associated SCM revision.
--
--   The date/time is UTC.
--

public function version_date(integer full = 0)
	--
	-- Date could be "unknown" if the version could not be determined in a very
	-- rare case. Thus, we also check for length here.
	--

	if full or is_developmental or length(version_info[REVISION_DATE]) < 10 then
		return version_info[REVISION_DATE]
	end if

	return version_info[REVISION_DATE][1..10]
end function

--****
-- === String Version Information
--

--**
-- Get the type version of the hosting Euphoria
--
-- Returns:
--   A **sequence**, representing the Type version string. Version 4.0.0 alpha 1
--   will return ##alpha 1##. 4.0.0 beta 2 will return ##beta 2##. 4.0.0 final,
--   or release, will return ##release##.
--

public function version_type()
	return version_info[VER_TYPE]
end function

--**
-- Get a normal version string
--
-- Parameters:
--   # ##full## - Return full version information regardless of
--     developmental/production status.
--
-- Returns:
--   A **#sequence**, representing the entire version information in one string.
--   The amount of detail you get depends on if this version of Euphoria has
--   been compiled as a developmental version (more detailed version information)
--   or if you have indicated TRUE for the ##full## argument.
--
-- Example return values
--   * "4.0.0 alpha 3 (ab8e98ab3ce4,2010-11-18)"
--   * "4.0.0 release (8d8874dc9e0a, 2010-12-22)"
--   * "4.1.5 development (12332:e8d8787af7de, 2011-07-18 12:55:03)"
--

public function version_string(integer full = 0)
	if full or is_developmental then
		return sprintf("%d.%d.%d %s (%d:%s, %s)", {
			version_info[MAJ_VER],
			version_info[MIN_VER],
			version_info[PAT_VER],
			version_info[VER_TYPE],
			version_revision(),
			version_node(),
			version_date(full)
		})
	else
		return sprintf("%d.%d.%d %s (%s, %s)", {
			version_info[MAJ_VER],
			version_info[MIN_VER],
			version_info[PAT_VER],
			version_info[VER_TYPE],
			version_node(),
			version_date(full)
		})
	end if
end function

--**
-- Get a short version string
--
-- Returns:
--   A **sequence**, representing the Major, Minor and Patch all in
--   one string.
--
--   Example return values:
--   * "4.0.0"
--   * "4.0.2"
--   * "5.6.2"
--

public function version_string_short()
	return sprintf("%d.%d.%d", version_info[MAJ_VER..PAT_VER])
end function

--**
-- Get a long version string
--
-- Parameters:
--   # ##full## - Return full version information regardless of
--     developmental/production status.
--
-- Returns:
--   A **#sequence**, representing the entire version information in one string.
--   The amount of detail you get depends on if this version of Euphoria has
--   been compiled as a developmental version (more detailed version information)
--   or if you have indicated TRUE for the ##full## argument.
--
-- Example return values
--   * "4.0.0 alpha 3 (ab8e98ab3ce4,2010-11-18) for Windows 32-bit"
--   * "4.0.0 release (8d8874dc9e0a, 2010-12-22) for Linux 32-bit"
--   * "4.1.5 development (12332:e8d8787af7de, 2011-07-18 12:55:03) for OS X 64-bit"
--

public function version_string_long(integer full = 0)
	return version_string(full) & " for " & platform_name() & " " & arch_bits()
end function

--****
-- === Copyright Information
--

--**
-- Get the copyright statement for Euphoria
--
-- Returns:
--   A **sequence**, containing 2 sequences: product name and copyright message
--
-- Example 1:
-- <eucode>
-- sequence info = euphoria_copyright()
-- -- info = {
-- --     "Euphoria v4.0.0 alpha 3",
-- --     "Copyright (c) XYZ, ABC\n" &
-- --     "Copyright (c) ABC, DEF"
-- -- }
-- </eucode>
--

public function euphoria_copyright()
	return {
		"Euphoria v" & version_string_long(),
		`
________
		Copyright (c) 2007-2011 by OpenEuphoria Group.
		Copyright (c) 1993-2006 by Rapid Deployment Software.
		All Rights Reserved.
		`
	}
end function

--**
-- Get the copyright statement for PCRE.
--
-- Returns:
--   A **sequence**, containing 2 sequences: product name and copyright message.
--
-- See Also:
--   [[:euphoria_copyright()]]
--

public function pcre_copyright()
	return {
		"PCRE v8.10",
		`
________Copyright (c) 1997-2010 University of Cambridge
		All Rights Reserved
		`
	}
end function

--**
-- Get all copyrights associated with this version of Euphoria.
--
-- Returns:
--   A **sequence**, of product names and copyright messages.
-- <eucode>
-- {
--     { ProductName, CopyrightMessage },
--     { ProductName, CopyrightMessage },
--     ...
-- }
-- </eucode>
--

public function all_copyrights()
	return {
		euphoria_copyright(),
		pcre_copyright()
	}
end function

--****
-- === Timing Information
--

--**
-- Euphoria start time.
--
-- This time represents the time Euphoria itself started. This
-- time is recorded before any of the users code is opened, parsed
-- or executed. It can provide accurate timing information as to
-- how long it takes for your application to go from start time
-- to usable time.
--
-- Returns:
--   An **atom** representing the start time of Euphoria itself
--

public function start_time()
	return version_info[START_TIME]
end function

--****
-- === Configure Information
--

--****
-- Signature:
-- <built-in> function include_paths(integer convert)
--
-- Description:
-- Returns the list of include paths, in the order in which they are searched
--
-- Parameters:
--    # ##convert## : an integer, nonzero to include converted path entries
--    that were not validated yet.
--
-- Returns:
--	A **sequence**, of strings, each holding a fully qualified include path.
--
-- Comments:
--
-- ##convert## is checked only under //Windows//. If a path has accented characters in it, then
-- it may or may not be valid to convert those to the OEM code page. Setting ##convert## to a nonzero value
-- will force conversion for path entries that have accents and which have not been checked to be valid yet.
-- The extra entries, if any, are returned at the end of the returned sequence.
--
-- The paths are ordered in the order they are searched:
-- # current directory
-- # configuration file,
-- # command line switches,
-- # EUINC
-- # a default based on EUDIR.
--
-- Example 1:
-- <eucode>
-- sequence s = include_paths(0)
-- -- s might contain
-- {
--   "/usr/euphoria/tests",
--   "/usr/euphoria/include",
--   "./include",
--   "../include"
-- }
-- </eucode>
--
-- See Also:
-- [[:eu.cfg]], [[:include]], [[:option_switches]]
--
