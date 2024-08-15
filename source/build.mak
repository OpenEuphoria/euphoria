##
## Usage:
##   make -f build.mak -j$(nproc) PLATFORM=platform-name [WITH_EUDOC=1] [WITH_CREOLE=1]
##       [WITH_EUBIN=0] [USE_CCACHE=0] [VERBOSE=0]
##
## Options:
##   -j$(nproc)     Specify same number of build jobs as available CPUs.
##   PLATFORM       Specify one of the platform names lited below.
##   USE_CCACHE     Enable ccache to speed up rebuilds. Must have ccache installed.
##   WITH_EUBIN     Build native eubins first to speed up subsequent steps.
##   WITH_EUDOC     Build latest EuDoc with the package and use it for htmldoc.
##   WITH_CREOLE    Build latest Creole with the package and use it for htmldoc.
##   VERBOSE        Show makefile commands being run.
##
## Dependencies:
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
## 4. Gets creole and eudoc from GitHub, builds the binaries and add them to the package.
## 4. Collects the artifacts from the build directory into a temporary directory in /tmp.
## 5. Creates a tarball or zip file in the source directory with the files from step 5.
##
## Note: I strongly recommend using ccache and -j$(nproc) to speed up your build times!
##

MAKEFLAGS += --no-print-directory
VARIABLES := $(.VARIABLES)

ifneq ($(shell which ccache),)
  HAVE_CCACHE := 1
else
  HAVE_CCACHE := 0
endif

WITH_EUDOC ?= 1
WITH_CREOLE ?= 1
WITH_EUBIN ?= 0
USE_CCACHE ?= $(HAVE_CCACHE)
VERBOSE ?= 0

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_NAME := $(notdir $(MAKEFILE_PATH))
TRUNKDIR := $(abspath $(dir $(MAKEFILE_PATH))..)

PLATFORMS := linux-arm linux-arm64 linux-x86 linux-x64 windows-x86 windows-x64
RELEASE ?= release

ifeq ($(findstring $(PLATFORM),$(PLATFORMS)),)
  $(error PLATFORM required, one of: $(PLATFORMS))
endif

GITHASH := $(shell git rev-parse --short=7 HEAD)
MAJ_VER := $(word 3,$(shell grep MAJ_VER version.h))
MIN_VER := $(word 3,$(shell grep MIN_VER version.h))
PAT_VER := $(word 3,$(shell grep PAT_VER version.h))
VERSION := $(MAJ_VER).$(MIN_VER).$(PAT_VER)

CC_SUFFIX := gcc

ifeq ($(PLATFORM),linux-arm)
  ARCH := ARM
  PLAT := LINUX
  CC_PREFIX := arm-linux-gnueabihf-
else ifeq ($(PLATFORM),linux-arm64)
  ARCH := ARM64
  PLAT := LINUX
  CC_PREFIX := aarch64-linux-gnu-
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

ifeq ($(USE_CCACHE),1)
  CCACHE := ccache
endif

CC = $(CCACHE) $(CC_PREFIX)$(CC_SUFFIX)
HOSTCC = $(CCACHE) gcc

BUILDDIR = $(TRUNKDIR)/source/build-$(PLATFORM)
EUBINDIR = $(TRUNKDIR)/source/build-eubin
EUCFG_FILE = $(BUILDDIR)/eu.cfg
CONFIG_FILE = config-$(PLATFORM).gnu
CONFIG_PARAMS = --arch=$(ARCH) --plat=$(PLAT) --build=$(BUILDDIR) --release=$(RELEASE) --cc-prefix='$(CCACHE) $(CC_PREFIX)'

COMPILED_FILES = \
  $(BUILDDIR)/eub$(EXE_EXT) \
  $(BUILDDIR)/eui$(EXE_EXT) \
  $(BUILDDIR)/euc$(EXE_EXT)

LIBRARY_FILES = \
  $(BUILDDIR)/eu$(LIB_EXT) \
  $(BUILDDIR)/eudbg$(LIB_EXT) \
  $(BUILDDIR)/euso$(LIB_EXT) \
  $(BUILDDIR)/eusodbg$(LIB_EXT)

TRANSLATED_FILES = \
  $(BUILDDIR)/eubind$(EXE_EXT) \
  $(BUILDDIR)/eucoverage$(EXE_EXT) \
  $(BUILDDIR)/eudis$(EXE_EXT) \
  $(BUILDDIR)/eudist$(EXE_EXT) \
  $(BUILDDIR)/eushroud$(EXE_EXT) \
  $(BUILDDIR)/eutest$(EXE_EXT)

ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
  TRANSLATED_FILES += $(BUILDDIR)/eubw$(EXE_EXT)
  TRANSLATED_FILES += $(BUILDDIR)/euiw$(EXE_EXT)
endif

BUILD_FILES = $(LIBRARY_FILES) $(COMPILED_FILES) $(TRANSLATED_FILES)
BUILD_TARGETS = $(patsubst $(BUILDDIR)/%,$(PACKAGE_PATH)/bin/%,$(BUILD_FILES))

ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
  RESOURCE_FILES = $(BUILDDIR)/eub.res $(BUILDDIR)/eubw.res $(BUILDDIR)/euc.res \
    $(BUILDDIR)/eui.res $(BUILDDIR)/euiw.res
  RESOURCE_TARGETS = $(patsubst $(BUILDDIR)/%,$(PACKAGE_PATH)/bin/%,$(RESOURCE_FILES))
endif

INCLUDE_FILES = $(wildcard $(TRUNKDIR)/include/*.e) $(wildcard $(TRUNKDIR)/include/*/*.e) \
  $(wildcard $(TRUNKDIR)/include/*/*/*.e*) $(wildcard $(TRUNKDIR)/include/*.h)
INCLUDE_TARGETS = $(patsubst $(TRUNKDIR)/%,$(PACKAGE_PATH)/%,$(INCLUDE_FILES))

HTMLDOC_FILES = $(addprefix $(BUILDDIR)/html/,$(shell eui docs.ex ../docs/manual.af)) \
  $(BUILDDIR)/html/images/next.png \
  $(BUILDDIR)/html/images/prev.png \
  $(BUILDDIR)/html/js/prototype.js \
  $(BUILDDIR)/html/js/scriptaculous.js \
  $(BUILDDIR)/html/js/search.js \
  $(BUILDDIR)/html/search.dat \
  $(BUILDDIR)/html/style.css
HTMLDOC_TARGETS = $(patsubst $(BUILDDIR)/html/%,$(PACKAGE_PATH)/docs/html/%,$(HTMLDOC_FILES))

OTHER_FILES = \
  $(wildcard $(TRUNKDIR)/demo/*/*.*) \
  $(wildcard $(TRUNKDIR)/demo/*.*) \
  $(wildcard $(TRUNKDIR)/tests/*/*/*) \
  $(wildcard $(TRUNKDIR)/tests/*/*) \
  $(wildcard $(TRUNKDIR)/tests/*) \
  $(TRUNKDIR)/bin/bench.ex \
  $(TRUNKDIR)/bin/bugreport.ex \
  $(TRUNKDIR)/bin/buildcpdb.ex \
  $(TRUNKDIR)/bin/ecp.dat \
  $(TRUNKDIR)/bin/edx.bat \
  $(TRUNKDIR)/bin/edx.ex \
  $(TRUNKDIR)/bin/eucoverage.ex \
  $(TRUNKDIR)/bin/euloc.ex \
  $(TRUNKDIR)/bin/make31.exw \
  $(TRUNKDIR)/License.txt
ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
  OTHER_FILES += $(TRUNKDIR)/makecfg.bat
else
  OTHER_FILES += $(TRUNKDIR)/makecfg.sh
endif
OTHER_TARGETS = $(patsubst $(TRUNKDIR)/%,$(PACKAGE_PATH)/%,$(OTHER_FILES))

PACKAGE_NAME = euphoria-$(VERSION)-$(PLATFORM)
PACKAGE_FILE = $(PACKAGE_NAME)-$(GITHASH)$(ZIP_EXT)
PACKAGE_PATH = /tmp/$(PACKAGE_NAME)
PACKAGE_TARGETS = $(BUILD_TARGETS) $(INCLUDE_TARGETS) $(DEMO_TARGETS) $(HTMLDOC_TARGETS) $(OTHER_TARGETS)

ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
  PACKAGE_TARGETS += $(RESOURCE_TARGETS)
endif

ifeq ($(WITH_EUBIN),1)
  CONFIG_PARAMS += --eubin=$(EUBINDIR) --use-binary-translator
  EUC = eui -eudir $(TRUNKDIR) -i $(TRUNKDIR)/include $(TRUNKDIR)/source/euc.ex
  EUBIN_PARAMS = --use-source-translator --build=$(EUBINDIR)
  ifdef USE_CCACHE
    EUBIN_PARAMS += --ar='ccache ar' --cc='ccache gcc'
  endif
  EUBIN_CONFIG = config-eubin.gnu
  EUBIN_EUCFG = $(EUBINDIR)/eu.cfg
  EUBIN_LIB = $(EUBINDIR)/eu.a
  EUBIN_EUC = $(EUBINDIR)/euc
  EUBIN_EUI = $(EUBINDIR)/eui
else
  CONFIG_PARAMS += --use-source-translator
  EUBIN_EUC = eui -i $(TRUNKDIR)/include $(TRUNKDIR)/source/euc.ex
  EUBIN_EUI = eui -i $(TRUNKDIR)/include $(TRUNKDIR)/source/eui.ex
  EUC = $(EUBIN_EUC)
endif

TRANSLATE = $(EUBIN_EUC)
EUCFLAGS = -c $(BUILDDIR)/eu.cfg -makefile -silent

ifeq ($(WITH_EUDOC),1)
  HTMLDOC_FLAGS += EUDOC="$(EUBIN_EUI) $(TRUNKDIR)/source/eudoc/eudoc.ex"
  PACKAGE_TARGETS += $(PACKAGE_PATH)/bin/eudoc$(EXE_EXT)
endif

ifeq ($(WITH_CREOLE),1)
  HTMLDOC_FLAGS += CREOLE="$(EUBIN_EUI) $(TRUNKDIR)/source/creole/creole.ex"
  PACKAGE_TARGETS += $(PACKAGE_PATH)/bin/creole$(EXE_EXT)
endif

ifneq ($(VERBOSE),1)
  ECHO := @
endif

ifeq ($(VERBOSE),1)
CMDLINE_VARIABLES := CC PLATFORM USE_CCACHE VERBOSE WITH_CREOLE WITH_EUBIN WITH_EUDOC
$(foreach v,$(sort $(CMDLINE_VARIABLES) $(filter-out .% %_FILES %_TARGETS $(VARIABLES) VARIABLES,$(.VARIABLES))),$(info $(v)=$($(v))))
endif

all: $(PACKAGE_FILE)

$(PACKAGE_FILE) : $(PACKAGE_TARGETS)
ifeq ($(ZIP_EXT),.tar.gz)
	$(ECHO)tar -C /tmp -I 'gzip -9' -vcf $(abspath $@) $(sort $(patsubst /tmp/%,%,$^))
else ifeq ($(ZIP_EXT),.zip)
	$(ECHO)cd /tmp && zip -r9 $(abspath $@) $(sort $(patsubst /tmp/%,%,$^))
endif

$(BUILD_TARGETS) : $(PACKAGE_PATH)/bin/% : $(BUILDDIR)/%
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@
	$(ECHO)$(CC_PREFIX)strip -g $@

library: static-library
shared-library: $(BUILDDIR)/euso$(LIB_EXT)
static-library: $(BUILDDIR)/eu$(LIB_EXT)
debug-library: debug-static-library
debug-shared-library: $(BUILDDIR)/eusodbg$(LIB_EXT)
debug-static-library: $(BUILDDIR)/eudbg$(LIB_EXT)

$(LIBRARY_FILES) : | $(CONFIG_FILE) $(EUCFG_FILE) $(BUILDDIR)/mkver$(EXE_EXT)
	$(ECHO)$(MAKE) CONFIG_FILE=$(CONFIG_FILE) $@

backend: $(BUILDDIR)/eub$(EXE_EXT)
interpreter: $(BUILDDIR)/eui$(EXE_EXT)
translator: $(BUILDDIR)/euc$(EXE_EXT)

$(BUILDDIR)/mkver$(EXE_EXT) : | $(CONFIG_FILE) $(EUCFG_FILE)
	$(ECHO)$(MAKE) CONFIG_FILE=$(CONFIG_FILE) HOSTCC="$(HOSTCC)" $@

$(COMPILED_FILES) : | $(LIBRARY_FILES) $(CONFIG_FILE) $(EUCFG_FILE) $(BUILDDIR)/mkver$(EXE_EXT)
	$(ECHO)$(MAKE) CONFIG_FILE=$(CONFIG_FILE) TRANSLATE="$(TRANSLATE)" $@

tools: eubind eucoverage eudis eudist eushroud eutest
eubind: $(BUILDDIR)/eubind$(EXE_EXT)
eucoverage: $(BUILDDIR)/eucoverage$(EXE_EXT)
eudis: $(BUILDDIR)/eudis$(EXE_EXT)
eudist: $(BUILDDIR)/eudist$(EXE_EXT)
eushroud: $(BUILDDIR)/eushroud$(EXE_EXT)
eutest: $(BUILDDIR)/eutest$(EXE_EXT)

$(TRANSLATED_FILES) : | $(LIBRARY_FILES) $(CONFIG_FILE) $(EUCFG_FILE)
	$(ECHO)$(MAKE) CONFIG_FILE=$(CONFIG_FILE) TRANSLATE="$(TRANSLATE)" $@

htmldoc: $(HTMLDOC_FILES)

$(filter-out $(BUILDDIR)/html/index.html,$(HTMLDOC_FILES)) : $(BUILDDIR)/html/index.html

$(BUILDDIR)/html/index.html : | $(CONFIG_FILE) $(EUCFG_FILE)
	@mkdir -p $(BUILDDIR)/html
	$(ECHO)$(MAKE) CONFIG_FILE=$(CONFIG_FILE) $(HTMLDOC_FLAGS) htmldoc

$(HTMLDOC_TARGETS) : $(PACKAGE_PATH)/docs/html/% : $(BUILDDIR)/html/%
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@

ifeq ($(PLATFORM),$(filter windows-%,$(PLATFORM)))
$(RESOURCE_TARGETS) : $(PACKAGE_PATH)/bin/% : $(BUILDDIR)/% | $(patsubst %.res,%.exe,$@)
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@
endif

$(INCLUDE_TARGETS) : $(PACKAGE_PATH)/include/% : $(TRUNKDIR)/include/%
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@

$(OTHER_TARGETS) : $(PACKAGE_PATH)/% : $(TRUNKDIR)/%
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@

$(CONFIG_FILE) $(EUCFG_FILE) :
	@mkdir -p $(BUILDDIR)
	$(ECHO)./configure $(CONFIG_PARAMS)
	$(ECHO)mv config.gnu $(CONFIG_FILE)

$(EUCFG_FILE) : | $(CONFIG_FILE)

.NOTPARALLEL: $(CONFIG_FILE) $(EUCFG_FILE)

clean:
	$(ECHO)rm -rf $(BUILDDIR) $(CONFIG_FILE) $(PACKAGE_PATH) $(PACKAGE_FILE)

dist-clean : clean
ifeq ($(WITH_EUBIN),1)
	$(ECHO)rm -rf $(EUBINDIR) $(EUBIN_CONFIG)
endif

ifeq ($(USE_CCACHE),1)
clear-cache:
	$(ECHO)rm -rf $(HOME)/.cache/ccache/*
endif

.PHONY : all clean dist-clean backend debug-library debug-shared-library debug-static-library eubind eucoverage eudis \
 eudist eushroud eutest htmldoc interpreter library shared-library static-library tools translator $(PLATFORMS)

ifeq ($(WITH_EUBIN),1)

$(BUILDDIR)/html/index.html : | $(EUBIN_EUI)

$(COMPILED_FILES) $(TRANSLATED_FILES) : | $(EUBIN_EUC)

eubin: $(EUBIN_LIB) $(EUBIN_EUC) $(EUBIN_EUI)

$(EUBIN_EUC) $(EUBIN_EUI): $(EUBIN_LIB)

$(EUBIN_LIB) $(EUBIN_EUC) $(EUBIN_EUI): | $(EUBIN_CONFIG) $(EUBIN_EUCFG)
	@mkdir -p $(EUBINDIR)
	$(ECHO)$(MAKE) CONFIG_FILE=$(EUBIN_CONFIG) HOSTCC="$(HOSTCC)" $@

$(EUBIN_CONFIG) : ; @mkdir -p $(EUBINDIR)
	$(ECHO)./configure $(EUBIN_PARAMS)
	$(ECHO)mv config.gnu $(EUBIN_CONFIG)

$(EUBIN_EUCFG) : | $(EUBIN_CONFIG)

$(TRANSLATED_FILES) : | $(EUBIN_EUC)

.PHONY: eubin

.NOTPARALLEL: $(EUBIN_CONFIG) $(EUBIN_EUCFG)

endif

ifeq ($(WITH_EUDOC),1)

$(BUILDDIR)/html/index.html : | $(TRUNKDIR)/source/eudoc/eudoc.ex

eudoc: $(PACKAGE_PATH)/bin/eudoc$(EXE_EXT)

$(PACKAGE_PATH)/bin/eudoc$(EXE_EXT) : $(BUILDDIR)/eudoc$(EXE_EXT)
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@

$(BUILDDIR)/eudoc$(EXE_EXT) : $(BUILDDIR)/eudoc-build/eudoc.mak
	$(ECHO)$(MAKE) -C $(dir $<) -f $(notdir $<) CC="$(CC)" LINKER="$(CC)"

$(BUILDDIR)/eudoc-build/eudoc.mak : $(TRUNKDIR)/source/eudoc/eudoc.ex | $(CONFIG_FILE) $(EUCFG_FILE) $(BUILDDIR)/eu$(LIB_EXT)
	$(ECHO)$(TRANSLATE) $(EUCFLAGS) -build-dir $(dir $@) -o $(BUILDDIR)/eudoc$(EXE_EXT) $<

$(TRUNKDIR)/source/eudoc/eudoc.ex :
	$(ECHO)git clone --depth=1 https://github.com/OpenEuphoria/eudoc $(TRUNKDIR)/source/eudoc

.PHONY: eudoc

endif

ifeq ($(WITH_CREOLE),1)

$(BUILDDIR)/html/index.html : | $(TRUNKDIR)/source/creole/creole.ex

creole: $(PACKAGE_PATH)/bin/creole$(EXE_EXT)

$(PACKAGE_PATH)/bin/creole$(EXE_EXT) : $(BUILDDIR)/creole$(EXE_EXT)
	@mkdir -p $(dir $@)
	$(ECHO)cp -p $< $@

$(BUILDDIR)/creole$(EXE_EXT) : $(BUILDDIR)/creole-build/creole.mak
	$(ECHO)$(MAKE) -C $(dir $<) -f $(notdir $<) CC="$(CC)" LINKER="$(CC)"

$(BUILDDIR)/creole-build/creole.mak : $(TRUNKDIR)/source/creole/creole.ex | $(CONFIG_FILE) $(EUCFG_FILE) $(BUILDDIR)/eu$(LIB_EXT)
	$(ECHO)$(TRANSLATE) $(EUCFLAGS) -build-dir $(dir $@) -o $(BUILDDIR)/creole$(EXE_EXT) $<

$(TRUNKDIR)/source/creole/creole.ex :
	$(ECHO)git clone --depth=1 https://github.com/OpenEuphoria/creole $(TRUNKDIR)/source/creole

.PHONY: creole

endif

