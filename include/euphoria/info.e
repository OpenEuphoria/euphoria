--****
-- == Euphoria Information
--
-- <<LEVELTOC depth=2>>

constant M_EU_INFO=75

enum MAJ_VER, MIN_VER, PAT_VER, VER_TYPE, REVISION

constant version_info = machine_func(M_EU_INFO, {})


--****
-- === Numeric Version Information
--

--****
-- === Compiled Platform Information

--**
-- Get the platform name
--
-- Returns:
--   A ##sequence## containing the platform name, i.e. Windows, Linux, DOS, FreeBSD or OS X.
--

public function platform_name()
ifdef DOS then
	return "DOS"
elsifdef WIN32 then
	return "Windows"
elsifdef LINUX then
	return "Linux"
elsifdef OSX then
	return "OS X"
elsifdef SUNOS then
	return "SunOS"
elsifdef FREEBSD then
	return "FreeBSD"
elsedef
	return "Unknown"
end ifdef
end function

--**
-- Get the version, as an integer, of the host Euphoria
--
-- Returns:
--   An ##integer## representing Major, Minor and Patch versions. Version
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
--   An ##integer## representing the Major version number. Version 4.0.0 will
--   return 4, version 5.6.2 will return 5, etc...
--

public function version_major()
  return version_info[MAJ_VER]
end function

--**
-- Get the minor version of the hosting Euphoria
--
-- Returns:
--   An ##integer## representing the Minor version number. Version 4.0.0
--   will return 0, 4.1.0 will return 1, 5.6.2 will return 6, etc...
--

public function version_minor()
  return version_info[MIN_VER]
end function

--**
-- Get the patch version of the hosting Euphoria
--
-- Returns:
--   An ##integer## representing the Path version number. Version 4.0.0
--   will return 0, 4.0.1 will return 1, 5.6.2 will return 2, etc...
--

public function version_patch()
  return version_info[PAT_VER]
end function

--**
-- Get the source code revision of the hosting Euphoria
--
-- Returns:
--   A text ##sequence## containing the source code manangement system's
-- revision number that the executing Euphoria was built from.
--

public function version_revision()
  return version_info[REVISION]
end function

--****
-- === String Version Information
--

--**
-- Get the type version of the hosting Euphoria
--
-- Returns:
--   A ##sequence## representing the Type version string. Version 4.0.0 alpha 1
--   will return ##alpha 1##. 4.0.0 beta 2 will return ##beta 2##. 4.0.0 final,
--   or release, will return ##release##.
--

public function version_type()
  return version_info[VER_TYPE]
end function

--**
-- Get a normal version string
--
-- Returns:
--   A ##sequence## representing the Major, Minor, Patch, Type and Revision all in
--   one string.
--
--   Example return values:
--   * "4.0.0 alpha 3 (r1234)"
--   * "4.0.0 release (r271)"
--   * "4.0.2 beta 1 (r2783)"
--

public function version_string()
  return sprintf("%d.%d.%d %s (r%s)", version_info)
end function

--**
-- Get a short version string
--
-- Returns:
--   A ##sequence## representing the Major, Minor and Patch all in
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
-- Returns:
--   Same value as [[:version_string]] with the addition of the platform
--   name.
--
--   Example return values:
--   * "4.0.0 alpha 3 - Windows"
--   * "4.0.0 release - Linux"
--   * "5.6.2 release - OS X"
--

public function version_string_long()
  return version_string() & " - " & platform_name()
end function

--****
-- === Copyright Information
--

--**
-- Get the copyright statement for Euphoria
--
-- Returns:
--   A ##sequence## containing 2 sequences: product name and copyright message
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
		"Euphoria v" & version_string(),
		#'
________
		Copyright (c) 2007-2009 by OpenEuphoria Group.
		Copyright (c) 1993-2006 by Rapid Deployment Software.
		All Rights Reserved.
		'
	}
end function

--**
-- Get the copyright statement for PCRE.
--
-- Returns:
--   A ##sequence## containing 2 sequences: product name and copyright message.
--
-- See Also:
--   [[:euphoria_copyright()]]
--

public function pcre_copyright()
	return {
		"PCRE v7.8",
		#'
________Copyright (c) 1997-2008 University of Cambridge
		All Rights Reserved
		'
	}
end function

--**
-- Get all copyrights associated with this version of Euphoria.
--
-- Returns:
--   A ##sequence## of product names and copyright messages.
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
