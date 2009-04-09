#
# CMake build file for Euphoria (All Platforms, All Compilers)
#
# Quick Instructions:
#
#   1. Download/Install CMake (http://cmake.org)
#   2. cd C:\Euphoria
#   3. mkdir build
#   4. cd build
#   5. cmake -G "Watcom WMake" ..
#   6. wmake
#
# If you prefer a GUI, you can:
#
#   1. Download/Install CMake (http://cmake.org)
#   2. cd C:\Euphoria
#   3. cmake-gui.exe
#   4. Select C:\Euphoria for the "Where is the source code:" prompt
#   5. Select C:\Euphoria\build for the "Where to build the binaries" prompt
#   6. Click "Configure"
#   7. Change any options you wish (use Advanced/Group View if you want more options)
#   8. Click "Configure" again if you change any options
#   9. cd C:\Euphoria\build
#  10. wmake
#
#   You can change these options any time by running cmake-gui again.
#

#
# CMake settings
#

CMAKE_MINIMUM_REQUIRED( VERSION 2.4 )

SET( CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS true )
SET( CMAKE_BUILD_TYPE "Release" )

INCLUDE( "$ENV{EUDIR}/source/CMakeMacros.cmake" )

#
# Project Setup
#

PROJECT( Euphoria )

#
# Versioning
#

SET( VER_MAJ 4 )
SET( VER_MIN 0 )
SET( VER_PAT 0 )
SET( VER_TYPE "development" )

#
# Options
#

OPTION( USE_INT_CODES   "Use INT_CODES"                  OFF )
OPTION( USE_MANAGED_MEM "Use Managed Memory"             ON  )
OPTION( ENABLE_DEBUG    "Enable debug"                   OFF )
OPTION( BUILD_RELEASE   "Build a release version"        OFF )
OPTION( BUILD_TOOLS     "Build the tools (eutest/eudoc)" OFF )
OPTION( BUILD_DOCS      "Build the documentation"        OFF )

ADD_SUBDIRECTORY( source )
