--****
-- == Euphoria Information
--
-- <<LEVELTOC depth=2>>

constant M_EU_INFO=75

enum MAJ_VER, MIN_VER, PAT_VER, VER_TYPE

constant version_info = machine_func(M_EU_INFO, {})

ifdef DOS then
	constant platform_name = "DOS"
elsifdef WIN32 then
	constant platform_name = "Windows"
elsifdef LINUX then
	constant platform_name = "Linux"
elsifdef OSX then
	constant platform_name = "OS X"
elsifdef FREEBSD then
	constant platform_name = "FreeBSD"
elsedef
	constant platform_name = "Unknown"
end ifdef

--****
-- === Numeric Version Information
--

--**
-- Get the version, as an integer, of the host Euphoria
--
-- Returns:
--   An ##integer## representing Major, Minor and Patch versions. Version
--   4.0.0 will return 400, 4.0.1 will return 401, the future version
--   5.6.2 will return 562, etc...
--

public function version()
  return (version_info[MAJ_VER] * 100) + 
	(version_info[MIN_VER] * 10) +
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
--   A ##sequence## representing the Major, Minor, Patch and Type all in
--   one string.
--
--   Example return values:
--   * "4.0.0 alpha 3"
--   * "4.0.0 release"
--   * "4.0.2 beta 1"
--

public function version_string()
  return sprintf("%d.%d.%d %s", version_info)
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
  return version_string() & " - " & platform_name
end function

