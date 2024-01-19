##
## Usage:
##   make -f build.mak -j$(nproc) PLATFORM=platform [USE_CCACHE=1]
##
## Options:
##   PLATFORM       Specify one of the platform names lited below.
##   USE_CCACHE     Enable ccache to speed up rebuilds. Must have ccache installed.
##   -j$(nproc)     Command to specify same number of build jobs as available CPUs.
##
## Platforms:
## - linux-x64 (none)
## - linux-arm (apt install {binutils,gcc}-arm-linux-gnu)
## - linux-x86 (apt install {binutils,gcc}-i686-linux-gnu)
## - windows-x64 (apt install {binutils,gcc}-mingw-w64-x86-64)
## - windows-x86 (apt install {binutils,gcc}-mingw-w64-i686)
##
## (All plaforms require the "build-essential" package in addition to the above.)
##
## This is a "meta" makefile that to create a full release of Euphoria. I assume you're on x86-64
## and using a recent distribution of Debian (11+) or Ubuntu (20.04+) or a derivative (e.g. Mint).
## See the platforms list above for the required packages. Here's how it works:
##
## 1. Runs ./configure with the options for (cross-)compiling to the target platform.
## 2. Renames config.gnu file created by ./configure to include the platform name.
## 3. Runs make, specifying the CONFIG_FILE option to the file created in steps 1-2.
## 4. Collects the artifacts from the build directory into a temporary directory in /tmp.
## 5. Creates a tarball or zip file in the source directory with the files from step 4.
##

MAKEFLAGS += --no-print-directory

MAKEFILE_NAME := $(abspath $(lastword $(MAKEFILE_LIST)))
TRUNKDIR := $(abspath $(dir $(MAKEFILE_NAME))..)

PLATFORMS := linux-arm linux-x86 linux-x64 windows-x86 windows-x64
RELEASE ?= release

ifeq ($(findstring $(PLATFORM),$(PLATFORMS)),)
  $(error PLATFORM required, one of: $(PLATFORMS))
endif

GITHASH := $(shell git rev-parse --short=7 HEAD)
MAJ_VER := $(word 3,$(shell grep MAJ_VER version.h))
MIN_VER := $(word 3,$(shell grep MIN_VER version.h))
PAT_VER := $(word 3,$(shell grep PAT_VER version.h))
VERSION := $(MAJ_VER).$(MIN_VER).$(PAT_VER)

ifeq ($(PLATFORM),linux-arm)
  ARCH := ARM
  PLAT := LINUX
  CC_PREFIX := arm-linux-gnueabihf-
else ifeq ($(PLATFORM),linux-x86)
  ARCH := x86
  PLAT := LINUX
  CC_PREFIX := i686-linux-gnu-
else ifeq ($(PLATFORM),linux-x64)
  ARCH := x86_64
  PLAT := LINUX
  CC_PREFIX := x86_64-linux-gnu-
else ifeq ($(PLATFORM),windows-x86)
  ARCH := x86
  PLAT := WINDOWS
  CC_PREFIX := i686-w64-mingw32-
else ifeq ($(PLATFORM),windows-x64)
  ARCH := x86_64
  PLAT := WINDOWS
  CC_PREFIX := x86_64-w64-mingw32-
endif

LIB_EXT := .a

ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
  EXE_EXT := .exe
  ZIP_EXT := .zip
else
  EXE_EXT :=
  ZIP_EXT := .tar.gz
endif

BUILDDIR = $(TRUNKDIR)/source/build-$(PLATFORM)
CONFIG_FILE = config-$(PLATFORM).gnu
CONFIG_PARAMS = --arch=$(ARCH) --plat=$(PLAT) --build=$(BUILDDIR) --release=$(RELEASE) --use-source-translator

ifeq ($(USE_CCACHE),1)
  CONFIG_PARAMS += --cc-prefix='ccache $(CC_PREFIX)'
  HOSTCC = 'ccache gcc'
else
  CONFIG_PARAMS += --cc-prefix=$(CC_PREFIX)
  HOSTCC = gcc
endif

PACKAGE_NAME = euphoria-$(VERSION)-$(PLATFORM)
PACKAGE_FILE = $(PACKAGE_NAME)-$(GITHASH)$(ZIP_EXT)
PACKAGE_PATH = /tmp/$(PACKAGE_NAME)

BUILD_FILES := eub$(EXE_EXT) euc$(EXE_EXT) eui$(EXE_EXT) eubind$(EXE_EXT) eucoverage$(EXE_EXT) eudis$(EXE_EXT) \
  eudist$(EXE_EXT) eushroud$(EXE_EXT) eutest$(EXE_EXT) eu$(LIB_EXT) eudbg$(LIB_EXT) euso$(LIB_EXT) eusodbg$(LIB_EXT)
BUILD_FILES := $(addprefix $(PACKAGE_PATH)/bin/,$(BUILD_FILES))

INCLUDE_FILES := $(wildcard $(TRUNKDIR)/include/*.e) $(wildcard $(TRUNKDIR)/include/*/*.e) \
  $(wildcard $(TRUNKDIR)/include/*/*/*.e*) $(wildcard $(TRUNKDIR)/include/*.h)
INCLUDE_FILES := $(patsubst $(TRUNKDIR)/%,$(PACKAGE_PATH)/%,$(INCLUDE_FILES))

HTMLDOC_FILES := $(shell eui docs.ex ../docs/manual.af) images/next.png images/prev.png \
  js/prototype.js js/scriptaculous.js js/search.js search.dat style.css
HTMLDOC_FILES := $(addprefix $(PACKAGE_PATH)/docs/html/,$(HTMLDOC_FILES))

OTHER_FILES = \
  $(PACKAGE_PATH)/bin/bench.ex \
  $(PACKAGE_PATH)/bin/bugreport.ex \
  $(PACKAGE_PATH)/bin/buildcpdb.ex \
  $(PACKAGE_PATH)/bin/ecp.dat \
  $(PACKAGE_PATH)/bin/edx.bat \
  $(PACKAGE_PATH)/bin/edx.ex \
  $(PACKAGE_PATH)/bin/eucoverage.ex \
  $(PACKAGE_PATH)/bin/euloc.ex \
  $(PACKAGE_PATH)/bin/make31.exw \
  $(PACKAGE_PATH)/License.txt

all : $(PACKAGE_FILE)

clean :
	@rm -rf $(PACKAGE_PATH) $(BUILDDIR)
	@rm -f $(CONFIG_FILE) $(PACKAGE_FILE)

$(PACKAGE_FILE) : $(BUILD_FILES) $(INCLUDE_FILES) $(HTMLDOC_FILES) $(OTHER_FILES)
ifeq ($(ZIP_EXT),.tar.gz)
	@tar -C /tmp -I 'gzip -9' -vcf $(abspath $@) $(sort $(patsubst /tmp/%,%,$^))
else ifeq ($(ZIP_EXT),.zip)
	@cd /tmp && zip -r9 $(abspath $@) $(sort $(patsubst /tmp/%,%,$^))
endif

$(BUILD_FILES) : $(PACKAGE_PATH)/bin/% : $(BUILDDIR)/% ; @mkdir -p $(dir $@) && cp -p $< $@ && $(CC_PREFIX)strip -g $@

$(INCLUDE_FILES) : $(PACKAGE_PATH)/include/% : $(TRUNKDIR)/include/% ; @mkdir -p $(dir $@) && cp -p $< $@

$(HTMLDOC_FILES) : $(PACKAGE_PATH)/docs/html/% : $(BUILDDIR)/html/% ; @mkdir -p $(dir $@) && cp -p $< $@

$(OTHER_FILES) : $(PACKAGE_PATH)/% : $(TRUNKDIR)/% ; @mkdir -p $(dir $@) && cp -p $< $@

$(BUILDDIR)/html/% : $(CONFIG_FILE) ; $(MAKE) CONFIG_FILE=$< htmldoc

$(BUILDDIR)/% : $(CONFIG_FILE) ; $(MAKE) CONFIG_FILE=$< HOSTCC=$(HOSTCC) $@

$(CONFIG_FILE) : ; ./configure $(CONFIG_PARAMS) && mv config.gnu $(CONFIG_FILE)

.PHONY : all clean $(PLATFORMS)
