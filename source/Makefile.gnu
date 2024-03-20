
# GNU Makefile for Euphoria Unix systems
#
# NOTE: This is meant to be used with GNU make,
#       so on BSD, you should use gmake instead
#       of make
#
# Syntax:
#
#   You must run configure before building
#
#   Configure the make system :  ./configure
#                                path/to/configure
#
#   Clean up binary files     :  make clean
#   Clean up binary and       :  make distclean clobber
#        translated files
#   eui, euc, eub, eu.a       :  make
#   Interpreter          (eui):  make interpreter
#   Translator           (euc):  make translator
#   Translator Library  (eu.a):  make library
#   Backend              (eub):  make backend
#   Utilities/Binder/Shrouder :  make tools (requires translator and library)
#   Run Unit Tests            :  make test (requires interpreter, translator, backend, binder)
#   Run Unit Tests with eu.ex :  make testeu
#   Run coverage analysis     :  make coverage
#   Code Page Database        :  make code-page-db
#   Generate automatic        :  make depend
#   dependencies (requires
#   makedepend to be installed)
#
#   Html Documentation        :  make htmldoc
#   PDF Documentation         :  make pdfdoc
#   Test eucode blocks in API
#       comments              :  make test-eucode
#
#   Note that Html and PDF Documentation require eudoc and creole
#   PDF docs also require a complete LaTeX installation
#
#   eudoc can be retrieved via make get-eudoc if you have
#   Mercurial installed.
#
#   creole can be retrieved via make get-creole if you have
#   Mercurial installed.
#


# ************************************************************************************************************* #
#                                       RULES FOR MODIFYING MAKE RULES                                          #
# ************************************************************************************************************* #
#  *  Inside make dependency lines DO NOT leave spaces around the equals sign in asssignment statements!        #
#     It is uglier but instead you must leave the definition stuck together with the variable, like this:       #
#                  EU_MAIN=$(FOO)                                                                               #
#     Consequence if this rule is not followed:  Possibly make will say there is nothing to be done to make a   #
#     target when it is in fact out of date                                                                     #
#                                                                                                               #
#                                                                                                               #
#  * Do not make symbolic targets as dependencies of other targets.                                             #
#    Consequence if this rule is not followed:   Make will try to make a target even if it is up to date        #
#                                                                                                               #
# ************************************************************************************************************* #

MAKEFLAGS += --no-print-directory

CONFIG_FILE = config.gnu
AR=$(CC_PREFIX)$(AR_SUFFIX)
CC=$(CC_PREFIX)$(CC_SUFFIX)
RC=$(CC_PREFIX)$(RC_SUFFIX)
ifndef CONFIG
  CONFIG = ${CURDIR}/$(CONFIG_FILE)
endif

PCRE_CC=$(CC)


include $(CONFIG)
include $(TRUNKDIR)/source/pcre/objects.mak

# so far this is all we support
  HOSTCC=gcc

ifeq "$(RELEASE)" "1"
  RELEASE_FLAG = -D EU_FULL_RELEASE
endif

ifdef ERUNTIME
  RUNTIME_FLAGS = -DERUNTIME
endif

ifdef EBACKEND
  BACKEND_FLAGS = -DBACKEND
endif

ifeq "$(EBSD)" "1"
  LDLFLAG=
  EBSDFLAG=-DEBSD -DEBSD62
  SEDFLAG=-Ei
  ifeq "$(EOSX)" "1"
    LDLFLAG=-lresolv
    EBSDFLAG=-DEBSD -DEBSD62 -DEOSX
  endif
  ifeq "$(EOPENBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DEOPENBSD
  endif
  ifeq "$(ENETBSD)" "1"
    EBSDFLAG=-DEBSD -DEBSD62 -DENETBSD
  endif
else
  ifeq "$(ARCH)" "ix86_64"
    LDLFLAG=-ldl -lresolv -lnsl
  else
    LDLFLAG=-ldl -lresolv
  endif
  PREREGEX=$(FROMBSDREGEX)
  SEDFLAG=-ri
endif
ifeq "$(EMINGW)" "1"
	EXE_EXT=.exe
	ifeq "$(EHOST)" "EWINDOWS"
		HOST_EXE_EXT=.exe
	endif
	EPTHREAD=
	EOSTYPE=-DEWINDOWS
	EBSDFLAG=-DEMINGW
	LDLFLAG=-static 
	SEDFLAG=-ri
	EOSFLAGS=$(NO_CYGWIN) -mwindows
	EOSFLAGSCONSOLE=$(NO_CYGWIN)
	EOSPCREFLAGS=$(NO_CYGWIN)
	EECUA=eu.a
	EECUDBGA=eudbg.a
	EECUSOA=euso.a
	EECUSODBGA=eusodbg.a
	ifdef EDEBUG
		EOSMING=
		ifdef FPIC
			LIBRARY_NAME=eusodbg.a
		else
			LIBRARY_NAME=eudbg.a
		endif
	else
		EOSMING=-ffast-math -Os
		ifdef FPIC
			LIBRARY_NAME=euso.a
		else
			LIBRARY_NAME=eu.a
		endif
	endif
	EUBW_RES=$(BUILDDIR)/eubw.res
	EUB_RES=$(BUILDDIR)/eub.res
	EUC_RES=$(BUILDDIR)/euc.res
	EUI_RES=$(BUILDDIR)/eui.res
	EUIW_RES=$(BUILDDIR)/euiw.res
	ifeq "$(MANAGED_MEM)" "1"
		ifeq "$(ALIGN4)" "1"
			MEM_FLAGS=-DEALIGN4
		else
			MEM_FLAGS=
		endif
	else
		ifeq "$(ALIGN4)" "1"
			MEM_FLAGS=-DEALIGN4 -DESIMPLE_MALLOC
		else
			MEM_FLAGS=-DESIMPLE_MALLOC
		endif
	endif
	CREATEDLLFLAGS=-Wl,--out-implib,lib818dll.a
else
	EXE_EXT=
	EPTHREAD=-pthread
	EOSTYPE=-DEUNIX
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSPCREFLAGS=
	EECUA=eu.a
	EECUDBGA=eudbg.a
	EECUSOA=euso.a
	EECUSODBGA=eusodbg.a
	ifdef EDEBUG
		ifdef FPIC
			LIBRARY_NAME=eusodbg.a
		else
			LIBRARY_NAME=eudbg.a
		endif
	else
		EOSMING=-ffast-math $(OPT) -Os
		ifdef FPIC
			LIBRARY_NAME=euso.a
		else
			LIBRARY_NAME=eu.a
		endif
	endif
	MEM_FLAGS=-DESIMPLE_MALLOC
	CREATEDLLFLAGS=
endif

MKVER=$(BUILDDIR)/mkver$(EXE_EXT)
ifeq "$(EMINGW)" "1"
	# Windowed backend
	EBACKENDW=eubw$(EXE_EXT)
endif
# Console based backend
EBACKENDC=eub$(EXE_EXT)
EECU=euc$(EXE_EXT)
EEXU=eui$(EXE_EXT)
HOST_EEXU=eui$(HOST_EXE_EXT)
EEXUW=euiw$(EXE_EXT)

LDLFLAG+= $(EPTHREAD)

ifdef EDEBUG
  DEBUG_FLAGS=-g3 -O0 -Wall
  CALLC_DEBUG=-g3
  EC_DEBUG=-D DEBUG
  EUC_DEBUG_FLAG=-debug
else
  DEBUG_FLAGS=-fomit-frame-pointer $(EOSMING)
endif

ifdef EPROFILE
  PROFILE_FLAGS=-pg -g
  ifndef EDEBUG
    DEBUG_FLAGS=$(EOSMING)
  endif
endif

ifdef ENO_DBL_CACHE
  MEM_FLAGS+=-DNO_DBL_CACHE
endif

ifdef COVERAGE
    COVERAGEFLAG=-fprofile-arcs -ftest-coverage
    DEBUG_FLAGS=-g3 -O0 -Wall
    COVERAGELIB=-lgcov
    OPT=
endif

ifndef TESTFILE
    COVERAGE_ERASE=-coverage-erase
endif

ifeq  "$(ELINUX)" "1"
    EBSDFLAG=-DELINUX
endif

# backwards compatibility
# don't make Unix users reconfigure for a MinGW-only change
ifndef CYPTRUNKDIR
    CYPTRUNKDIR=$(TRUNKDIR)
endif
ifndef CYPBUILDDIR
    CYPBUILDDIR=$(BUILDDIR)
endif

ifeq "$(ELINUX)" "1"
    PLAT=LINUX
else ifeq "$(EOPENBSD)" "1"
    PLAT=OPENBSD
else ifeq "$(ENETBSD)" "1"
    PLAT=NETBSD
else ifeq "$(EFREEBSD)" "1"
    PLAT=FREEBSD
else ifeq "$(EOSX)" "1"
    PLAT=OSX
else ifeq "$(EMINGW)" "1"
    PLAT=WINDOWS
endif

# We mustn't use eui rather than $(EEXU) in these three lines below.   When this translates from Unix, the interpreter we call to do the translation must not have a .exe extension.
ifeq  "$(EUBIN)" ""
    EXE=$(EEXU)
    HOST_EXE=$(HOST_EEXU)
else
    EXE=$(EUBIN)/$(EEXU)
    HOST_EXE=$(EUBIN)/$(HOST_EEXU)
endif
# The -i command with the include directory in the form we need the EUPHORIA binaries to see them.
# (Use a drive id 'C:')
# [Which on Windows is different from the how it is expressed in for the GNU binaries. ]
CYPINCDIR=-i $(CYPTRUNKDIR)/include

BE_CALLC = be_callc

ifeq "$(EUDOC)" ""
    EUDOC=eudoc
endif

ifeq "$(CREOLE)" ""
    CREOLE=creole
endif

ifeq "$(TRANSLATE)" "euc"
	TRANSLATE="euc"
else
#   We MUST pass these arguments to $(EXE), for $(EXE) is not and shouldn't be governed by eu.cfg in BUILDDIR.
#   Euphoria programs under Windows use paths of the form "c:\euphoria\program" even when compiling under MING or Cygwin!  This means they must take CYP* macros CYPINCDIR and CYPTRUNKDIR as arguments.
	TRANSLATE=$(HOST_EXE) $(CYPINCDIR) $(EC_DEBUG) $(EFLAG) $(CYPTRUNKDIR)/source/euc.ex $(EUC_DEBUG_FLAG)
endif

ifeq "$(ARCH)" "ARM"
    TARCH_FLAG=ARM
	ARCH_FLAG=-DEARM
#	MSIZE=-march=armv6 -mfpu=vfp -mfloat-abi=hard
	MSIZE=-marm
else ifeq "$(ARCH)" "ix86"
    TARCH_FLAG=X86
	ARCH_FLAG=-DEX86
	# Mostly for OSX, but prevents bad conversions double<-->long
	# See ticket #874
	FP_FLAGS=-mno-sse
else ifeq "$(ARCH)" "ix86_64"
    TARCH_FLAG=X86_64
	ARCH_FLAG=-DEX86_64
endif

WARNINGFLGS =
ifeq "$(MANAGED_MEM)" "1"
    FE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(EPTHREAD) -Wno-unused-variable -Wno-unused-but-set-variable -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(FP_FLAGS)                $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(MEM_FLAGS) $(OPT)
else
    FE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(EPTHREAD) -Wno-unused-variable -Wno-unused-but-set-variable -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(FP_FLAGS) $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(OPT)
endif
BE_FLAGS =  $(ARCH_FLAG) $(COVERAGEFLAG) $(MSIZE) $(OPT) $(EPTHREAD) -c -Wall $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(FP_FLAGS) $(DEBUG_FLAGS) $(MEM_FLAGS) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(FPIC) -I$(TRUNKDIR)/source

# Disable Position Independent Executable (PIE)
ifneq (,$(shell $(CC) -v 2>&1 | grep default-pie))
	LDLFLAG += -no-pie
	FE_FLAGS += -no-pie
	BE_FLAGS += -no-pie
endif

# TODO XXX should syncolor.e really be in EU_INTERPRETER_FILES ?

EU_CORE_FILES = \
	$(TRUNKDIR)/source/block.e \
	$(TRUNKDIR)/source/common.e \
	$(TRUNKDIR)/source/coverage.e \
	$(TRUNKDIR)/source/emit.e \
	$(TRUNKDIR)/source/error.e \
	$(TRUNKDIR)/include/std/fenv.e \
	$(TRUNKDIR)/source/fwdref.e \
	$(TRUNKDIR)/source/inline.e \
	$(TRUNKDIR)/source/keylist.e \
	$(TRUNKDIR)/source/main.e \
	$(TRUNKDIR)/source/msgtext.e \
	$(TRUNKDIR)/source/mode.e \
	$(TRUNKDIR)/source/opnames.e \
	$(TRUNKDIR)/source/parser.e \
	$(TRUNKDIR)/source/pathopen.e \
	$(TRUNKDIR)/source/platform.e \
	$(TRUNKDIR)/source/preproc.e \
	$(TRUNKDIR)/source/reswords.e \
	$(TRUNKDIR)/source/scanner.e \
	$(TRUNKDIR)/source/shift.e \
	$(TRUNKDIR)/source/syncolor.e \
	$(TRUNKDIR)/source/symtab.e \
	$(TRUNKDIR)/source/fwdref.e


EU_INTERPRETER_FILES = \
	$(TRUNKDIR)/source/backend.e \
	$(TRUNKDIR)/source/c_out.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/global.e \
	$(TRUNKDIR)/source/intinit.e \
	$(TRUNKDIR)/source/eui.ex

EU_TRANSLATOR_FILES = \
	$(TRUNKDIR)/source/buildsys.e \
	$(TRUNKDIR)/source/c_decl.e \
	$(TRUNKDIR)/source/c_out.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compile.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/global.e \
	$(TRUNKDIR)/source/traninit.e \
	$(TRUNKDIR)/source/euc.ex

EU_BACKEND_RUNNER_FILES = \
	$(TRUNKDIR)/source/backend.e \
	$(TRUNKDIR)/source/il.e \
	$(TRUNKDIR)/source/cominit.e \
	$(TRUNKDIR)/source/compress.e \
	$(TRUNKDIR)/source/error.e \
	$(TRUNKDIR)/source/intinit.e \
	$(TRUNKDIR)/source/mode.e \
	$(TRUNKDIR)/source/reswords.e \
	$(TRUNKDIR)/source/pathopen.e \
	$(TRUNKDIR)/source/common.e \
	$(TRUNKDIR)/source/backend.ex
PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre$(FPIC)/,$(PCRE_OBJECTS))

EU_BACKEND_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_debug.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_execute.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_main.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_coverage.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rterror.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_syncolor.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_symtab.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(PREFIXED_PCRE_OBJECTS)

EU_LIB_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_coverage.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_syncolor.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_debug.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_symtab.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_execute.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_rterror.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_main.o \
	$(PREFIXED_PCRE_OBJECTS)

# The bare include directory in this checkout as we want the make file to see it.  Forward slashes, no 'C:'.
# Which (on Windows) is different to the way we need to give paths to EUPHORIA's binaries.
INCDIR = $(TRUNKDIR)/include

EU_STD_INC = \
	$(wildcard $(INCDIR)/std/*.e) \
	$(wildcard $(INCDIR)/std/unix/*.e) \
	$(wildcard $(INCDIR)/std/net/*.e) \
	$(wildcard $(INCDIR)/std/win32/*.e) \
	$(wildcard $(INCDIR)/euphoria/*.e)

DOCDIR = $(TRUNKDIR)/docs
EU_DOC_SOURCE = \
	$(EU_STD_INC) \
	$(DOCDIR)/manual.af \
	$(wildcard $(TRUNKDIR)/include/*.*) \
	$(TRUNKDIR)/License.txt \
	$(wildcard $(TRUNKDIR)/demo/*.*) \
	$(wildcard $(TRUNKDIR)/demo/*/*.*) \
	$(wildcard $(DOCDIR)/*.txt) \
	$(wildcard $(INCDIR)/euphoria/debug/*.e) \
	$(wildcard $(DOCDIR)/release/*.txt)

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all :
	$(MAKE) code-page-db interpreter translator library debug-library backend lib818
	$(MAKE) shared-library debug-shared-library
	$(MAKE) tools

BUILD_DIRS = \
	$(BUILDDIR)/include/ \
	$(BUILDDIR)/intobj/ \
	$(BUILDDIR)/intobj/back/ \
	$(BUILDDIR)/transobj/ \
	$(BUILDDIR)/transobj/back/ \
	$(BUILDDIR)/libobj/ \
	$(BUILDDIR)/libobj/back/ \
	$(BUILDDIR)/libobjdbg/ \
	$(BUILDDIR)/libobjdbg/back/ \
	$(BUILDDIR)/backobj/ \
	$(BUILDDIR)/backobj/back/ \
	$(BUILDDIR)/libobj-fPIC/ \
	$(BUILDDIR)/libobj-fPIC/back/ \
	$(BUILDDIR)/libobjdbg-fPIC/ \
	$(BUILDDIR)/libobjdbg-fPIC/back/

clean :
	-for f in $(BUILD_DIRS) ; do \
		rm -r $${f} ; \
	done ;
	-rm -r $(BUILDDIR)/pcre
	-rm -r $(BUILDDIR)/pcre_fpic
	-rm $(BUILDDIR)/*pdf
	-rm $(BUILDDIR)/*txt
	-rm -r $(BUILDDIR)/*-build
	-rm $(BUILDDIR)/eui$(EXE_EXT) $(BUILDDIR)/$(EEXUW)
	-rm $(BUILDDIR)/$(EECU)
	-rm $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW)
	-rm $(BUILDDIR)/eu.a
	-rm $(BUILDDIR)/eudbg.a
	-rm $(BUILDDIR)/euso.a
	-for f in $(EU_TOOLS) ; do \
		rm $${f} ; \
	done ;
	rm -f $(BUILDDIR)/euphoria.{pdf,txt}
	-rm $(BUILDDIR)/ver.cache
	-rm $(BUILDDIR)/mkver$(EXE_EXT)
	-rm $(BUILDDIR)/eudist$(EXE_EXT) $(BUILDDIR)/echoversion$(EXE_EXT)
	-rm $(BUILDDIR)/test818.o
	-rm -r $(BUILDDIR)/html
	-rm -r $(BUILDDIR)/coverage
	-rm -r $(BUILDDIR)/manual
	-rm $(TRUNKDIR)/tests/lib818.dll
	-rm $(BUILDDIR)/*.res

clobber distclean : clean
	-rm -f $(CONFIG)
	-rm -f Makefile
	-rm -fr $(BUILDDIR)
	-rm eu.cfg

	$(MAKE) -C pcre CONFIG=$(BUILDDIR)/$(CONFIG) clean
	$(MAKE) -C pcre CONFIG=$(BUILDDIR)/$(CONFIG) FPIC=-fPIC clean


.PHONY: clean distclean clobber all htmldoc manual lib818 testaux

ifeq "$(OBJDIR)" "libobj"
$(BUILDDIR)/$(EECUA) : $(EU_LIB_OBJECTS) | $(BUILDDIR)
	$(AR) -rc $(BUILDDIR)/$(EECUA) $(EU_LIB_OBJECTS)
else
$(BUILDDIR)/$(EECUA) : $(wildcard $(TRUNKDIR)/source/*.[ch]) $(wildcard $(TRUNKDIR)/source/pcre/*.[ch]) | $(BUILDDIR)
	$(MAKE) $(BUILDDIR)/$(EECUA) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG= EPROFILE=$(EPROFILE)
endif


ifeq "$(OBJDIR)" "libobjdbg"
$(BUILDDIR)/$(EECUDBGA) : $(EU_LIB_OBJECTS) | $(BUILDDIR)
	$(AR) -rc $(BUILDDIR)/$(EECUDBGA) $(EU_LIB_OBJECTS)
else
$(BUILDDIR)/$(EECUDBGA) : $(wildcard $(TRUNKDIR)/source/*.[ch]) $(wildcard $(TRUNKDIR)/source/pcre/*.[ch]) | $(BUILDDIR)
	$(MAKE) $(BUILDDIR)/$(EECUDBGA) OBJDIR=libobjdbg ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE)
endif


ifeq "$(OBJDIR)" "libobj-fPIC"
$(BUILDDIR)/$(EECUSOA) : $(EU_LIB_OBJECTS) | $(BUILDDIR)
	$(AR) -rc $(BUILDDIR)/$(EECUSOA) $(EU_LIB_OBJECTS)
else
$(BUILDDIR)/$(EECUSOA) : $(BUILDDIR)/$(EECUA) $(wildcard $(TRUNKDIR)/source/*.[ch]) $(wildcard $(TRUNKDIR)/source/pcre/*.[ch]) | $(BUILDDIR)
ifneq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EECUSOA) OBJDIR=libobj-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG= EPROFILE=$(EPROFILE) FPIC=-fPIC
else
	ln -f $(BUILDDIR)/$(EECUA) $(BUILDDIR)/$(EECUSOA)
endif
endif


ifeq "$(OBJDIR)" "libobjdbg-fPIC"
$(BUILDDIR)/$(EECUSODBGA) : $(EU_LIB_OBJECTS) | $(BUILDDIR)
	$(AR) -rc $(BUILDDIR)/$(EECUSODBGA) $(EU_LIB_OBJECTS)
else
$(BUILDDIR)/$(EECUSODBGA) : $(BUILDDIR)/$(EECUDBGA) $(wildcard $(TRUNKDIR)/source/*.[ch]) $(wildcard $(TRUNKDIR)/source/pcre/*.[ch]) | $(BUILDDIR)
ifneq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EECUSODBGA) OBJDIR=libobjdbg-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE) FPIC=-fPIC
else
	ln -f $(BUILDDIR)/$(EECUDBGA) $(BUILDDIR)/$(EECUSODBGA)
endif
endif

shared-library : $(BUILDDIR)/$(EECUSOA)

debug-shared-library : $(BUILDDIR)/$(EECUSODBGA)

library : $(BUILDDIR)/$(EECUA)

debug-library : $(BUILDDIR)/$(EECUDBGA)

builddirs : | $(BUILD_DIRS)

$(BUILD_DIRS) :
	@mkdir -p $@

ifeq "$(ROOTDIR)" ""
ROOTDIR=$(TRUNKDIR)
endif

code-page-db : $(BUILDDIR)/ecp.dat $(TRUNKDIR)/tests/ecp.dat

$(BUILDDIR)/ecp.dat : $(BUILDDIR)/$(EEXU) $(TRUNKDIR)/source/codepage/*.ecp msgtext.e | $(BUILDDIR)
	( $(BUILDDIR)/$(EEXU) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/buildcpdb.ex -p$(CYPTRUNKDIR)/source/codepage -o$(CYPBUILDDIR) ) || eui -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/buildcpdb.ex -p$(CYPTRUNKDIR)/source/codepage -o$(CYPBUILDDIR)

$(TRUNKDIR)/tests/ecp.dat : $(BUILDDIR)/ecp.dat
	cp -fl $(BUILDDIR)/ecp.dat $(TRUNKDIR)/tests/ecp.dat || cp -f $(BUILDDIR)/ecp.dat $(TRUNKDIR)/tests/ecp.dat

interpreter : $(BUILDDIR)/$(EEXU)

translator : $(BUILDDIR)/$(EECU)

EUBIND=eubind$(EXE_EXT)
EUSHROUD=eushroud$(EXE_EXT)

binder : $(BUILDDIR)/$(EUBIND)

shrouder : $(BUILDDIR)/$(EUSHROUD)

.PHONY : library debug-library
.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : code-page-db
.PHONY : binder


$(BUILDDIR)/intobj/main-.c : EU_TARGET=eui.ex
$(BUILDDIR)/intobj/main-.c : $(BUILDDIR)/include/be_ver.h
$(BUILDDIR)/intobj/main-.c : $(BUILDDIR)/include/be_ver.h

euisource : $(BUILDDIR)/intobj/main-.c

$(BUILDDIR)/transobj/main-.c : EU_TARGET=euc.ex
$(BUILDDIR)/transobj/main-.c : $(BUILDDIR)/include/be_ver.h

eucsource : $(BUILDDIR)/transobj/main-.c

$(BUILDDIR)/backobj/main-.c : EU_TARGET=backend.ex
$(BUILDDIR)/backobj/main-.c : $(BUILDDIR)/include/be_ver.h

backendsource : $(BUILDDIR)/backobj/main-.c

source : builddirs
	$(MAKE) $(BUILDDIR)/intobj/main-.c OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) $(BUILDDIR)/transobj/main-.c OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) $(BUILDDIR)/backobj/main-.c OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

HASH := $(shell git show --format='%H' | head -1)
SHORT_HASH := $(shell git show --format='%h' | head -1)

ifneq "$(VERSION)" ""
SOURCEDIR=euphoria-$(PLAT)-$(VERSION)
else

ifeq "$(PLAT)" ""
SOURCEDIR=euphoria-$(SHORT_HASH)
TARGETPLAT=
else
SOURCEDIR=euphoria-$(PLAT)-$(SHORT_HASH)
TARGETPLAT=-plat $(PLAT)
endif

endif

source-tarball : $(BUILDDIR)/$(SOURCEDIR)-src.tar.gz

$(BUILDDIR)/$(SOURCEDIR)-src.tar.gz : $(MKVER) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_INTERPRETER_FILES) $(EU_CORE_FILES) $(EU_STD_INC) $(wildcard *.c) $(BUILDDIR)/intobj/main-.c $(BUILDDIR)/transobj/main-.c $(BUILDDIR)/backobj/main-.c | $(BUILDDIR)
	rm -rf $(BUILDDIR)/$(SOURCEDIR)
	mkdir -p $(BUILDDIR)/$(SOURCEDIR)/build
	(cd ..;git archive --format=tar $(HASH) . ) | tar xf - -C $(BUILDDIR)/$(SOURCEDIR)
	(cd $(BUILDDIR); find  . -maxdepth 2 \( -name '*.[ch]' -o -name ver.cache -o -name mkver$(EXE_EXT) \)  | cpio -oH tar ) | (cd $(BUILDDIR)/$(SOURCEDIR)/build && cpio -i -H tar --make-directories )
	(cd $(BUILDDIR); tar -czf $(SOURCEDIR)-src.tar.gz $(SOURCEDIR) )
	rm -rf $(BUILDDIR)/$(SOURCEDIR)
ifneq "$(VERSION)" ""
	cd $(BUILDDIR) && mkdir -p $(PLAT) && mv $(SOURCEDIR)-src.tar.gz $(PLAT)
endif

.PHONY : euisource
.PHONY : eucsource
.PHONY : backendsource
.PHONY : source

ifeq "$(EMINGW)" "1"
$(EUI_RES) :  $(TRUNKDIR)/source/eui.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
$(EUIW_RES) :  $(TRUNKDIR)/source/euiw.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EEXU) :  EU_TARGET=eui.ex
$(BUILDDIR)/$(EEXU) :  EU_MAIN=$(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EEXU) :  $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EEXU) :  $(wildcard $(BUILDDIR)/intobj/*.c) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES) $(wildcard be_*.c)
$(BUILDDIR)/$(EEXU) :  $(BUILDDIR)/include/be_ver.h $(TRUNKDIR)/source/pcre/*.c
ifeq "$(OBJDIR)" "intobj"
$(BUILDDIR)/$(EEXU) :  EU_OBJS="$(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EUI_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EUIW_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(MSIZE) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
endif
else
$(BUILDDIR)/$(EEXU) : | $(BUILDDIR)/intobj $(BUILDDIR)/intobj/back
ifeq "$(EUPHORIA)" "1"
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif

$(BUILDDIR)/$(OBJDIR)/back/be_machine.o : $(BUILDDIR)/include/be_ver.h

ifeq "$(EMINGW)" "1"
$(EUC_RES) :  $(TRUNKDIR)/source/euc.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EECU) :  EU_TARGET=euc.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN=$(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EECU) :  $(wildcard $(BUILDDIR)/transobj/*.c) $(EU_MAIN) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES) $(wildcard be_*.c)
$(BUILDDIR)/$(EECU) :  $(BUILDDIR)/include/be_ver.h $(TRUNKDIR)/source/pcre/*.c $(EUC_RES)
ifeq "$(OBJDIR)" "transobj"
$(BUILDDIR)/$(EECU) :  EU_OBJS="$(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EECU) :  $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
	$(CC) $(EOSFLAGSCONSOLE) $(EUC_RES) $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(MSIZE) -o $(BUILDDIR)/$(EECU)
else
$(BUILDDIR)/$(EECU) : | $(BUILDDIR)/transobj $(BUILDDIR)/transobj/back
ifeq "$(EUPHORIA)" "1"
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif
	$(MAKE) $(BUILDDIR)/$(EECU) OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif

backend :  $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW)

ifeq "$(EMINGW)" "1"
$(EUB_RES) :  $(TRUNKDIR)/source/eub.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
$(EUBW_RES) :  $(TRUNKDIR)/source/eubw.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_TARGET=backend.ex
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_MAIN=$(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)  $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(CYPBUILDDIR)/$(LIBRARY_NAME)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(wildcard $(BUILDDIR)/backobj/*.c) $(EU_MAIN)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(BUILDDIR)/include/be_ver.h $(TRUNKDIR)/source/pcre/*.c
ifeq "$(OBJDIR)" "backobj"
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_OBJS="$(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(EUB_RES) $(EUBW_RES)
	$(CC) $(EOSFLAGS) $(EUB_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDC)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGS) $(EUBW_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDW)
endif
else
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) : | $(BUILDDIR)/backobj $(BUILDDIR)/backobj/back
ifeq "$(EUPHORIA)" "1"
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)  EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif
	$(MAKE) $(BUILDDIR)/$(EBACKENDC) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
ifeq "$(EMINGW)" "1"
	$(MAKE) $(BUILDDIR)/$(EBACKENDW) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif
endif

ifeq "$(HG)" ""
HG=git
endif

.PHONY: update-version-cache
update-version-cache : $(BUILDDIR)/ver.cache

$(MKVER): mkver.c $(BUILDDIR)/include/
	$(HOSTCC) -o $@ $<

$(BUILDDIR)/ver.cache : $(MKVER) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_INTERPRETER_FILES) $(EU_CORE_FILES) $(EU_STD_INC) $(wildcard *.c)
	$(MKVER) "$(HG)" "$(BUILDDIR)/ver.cache" "$(BUILDDIR)/include/be_ver.h" $(EREL_TYPE)$(RELEASE)

$(BUILDDIR)/include/be_ver.h:  $(BUILDDIR)/ver.cache $(BUILD_DIRS)

###############################################################################
#
# Documentation
#
###############################################################################

get-eudoc: $(TRUNKDIR)/source/eudoc/eudoc.ex
get-creole: $(TRUNKDIR)/source/creole/creole.ex

$(TRUNKDIR)/source/eudoc/eudoc.ex :
	git clone git://github.com/openeuphoria/eudoc $(TRUNKDIR)/source/eudoc

$(TRUNKDIR)/source/creole/creole.ex :
	git clone git://github.com/openeuphoria/creole $(TRUNKDIR)/source/creole

$(BUILDDIR)/euphoria.txt : $(EU_DOC_SOURCE)
	cd $(TRUNKDIR)/docs && $(EUDOC) -d HTML --strip=2 --verbose -a manual.af -o $(CYPBUILDDIR)/euphoria.txt

$(BUILDDIR)/docs/index.html : $(BUILDDIR)/euphoria.txt $(DOCDIR)/*.txt $(TRUNKDIR)/include/std/*.e
	-mkdir -p $(BUILDDIR)/docs/images
	-mkdir -p $(BUILDDIR)/docs/js
	cd $(CYPTRUNKDIR)/docs && $(CREOLE) -A -d=$(CYPTRUNKDIR)/docs/ -t=template.html -o=$(CYPBUILDDIR)/docs $(CYPBUILDDIR)/euphoria.txt
	cp $(DOCDIR)/html/images/* $(BUILDDIR)/docs/images
	cp $(DOCDIR)/style.css $(BUILDDIR)/docs

manual : $(BUILDDIR)/docs/index.html

manual-send : manual
	$(SCP) $(TRUNKDIR)/docs/style.css $(BUILDDIR)/docs/*.html $(oe_username)@openeuphoria.org:/home/euweb/docs

manual-reindex:
	$(SSH) $(oe_username)@openeuphoria.org "cd /home/euweb/prod/euweb/source/ && sh reindex_manual.sh"

manual-upload: manual-send manual-reindex

$(BUILDDIR)/html/index.html : $(BUILDDIR)/euphoria.txt $(DOCDIR)/offline-template.html
	-mkdir -p $(BUILDDIR)/html/images
	-mkdir -p $(BUILDDIR)/html/js
	cd $(CYPTRUNKDIR)/docs && $(CREOLE) -A -d=$(CYPTRUNKDIR)/docs/ -t=offline-template.html -o=$(CYPBUILDDIR)/html $(CYPBUILDDIR)/euphoria.txt
	cp $(DOCDIR)/*js $(BUILDDIR)/html/js
	cp $(DOCDIR)/html/images/* $(BUILDDIR)/html/images
	cp $(DOCDIR)/style.css $(BUILDDIR)/html

$(BUILDDIR)/html/js/scriptaculous.js: $(DOCDIR)/scriptaculous.js  | $(BUILDDIR)/html/js
	copy $(DOCDIR)/scriptaculous.js $^@

$(BUILDDIR)/html/js/prototype.js: $(DOCDIR)/prototype.js  | $(BUILDDIR)/html/js
	copy $(DOCDIR)/prototype.js $^@

htmldoc : $(BUILDDIR)/html/index.html

#
# PDF manual
#

pdfdoc : $(BUILDDIR)/euphoria.pdf

$(BUILDDIR)/pdf/euphoria.txt : $(EU_DOC_SOURCE)
	-mkdir -p $(BUILDDIR)/pdf
	$(EUDOC) -d PDF --single --strip=2 -a $(TRUNKDIR)/docs/manual.af -o $(CYPBUILDDIR)/pdf/euphoria.txt

$(BUILDDIR)/pdf/euphoria.tex : $(BUILDDIR)/pdf/euphoria.txt $(TRUNKDIR)/docs/template.tex
	cd $(TRUNKDIR)/docs && $(CREOLE) -f latex -A -t=$(TRUNKDIR)/docs/template.tex -o=$(CYPBUILDDIR)/pdf $<

$(BUILDDIR)/euphoria.pdf : $(BUILDDIR)/pdf/euphoria.tex
	cd $(TRUNKDIR)/docs && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && cp $(BUILDDIR)/pdf/euphoria.pdf $(BUILDDIR)/

pdfdoc-initial : $(BUILDDIR)/euphoria.pdf
	cd $(TRUNKDIR)/docs && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && cp $(BUILDDIR)/pdf/euphoria.pdf $(BUILDDIR)/

.PHONY : pdfdoc-initial pdfdoc

###############################################################################
#
# Testing Targets
#
###############################################################################

#
# Test <eucode>...</eucode> blocks found in our API reference docs
#

.PHONY: test-eucode

test-eucode :
	$(EUDOC) --single --verbose --test-eucode --work-dir=$(CYPBUILDDIR)/eudoc_test -o $(BUILDDIR)/test_eucode.txt $(EU_STD_INC)
	$(CREOLE) -o $(CYPBUILDDIR) $(CYPBUILDDIR)/test_eucode.txt

#
# Unit Testing
#
test : $(BUILDDIR)/test-report.html


$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : EUDIR=$(TRUNKDIR)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : EUCOMPILEDIR=$(TRUNKDIR)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : EUCOMPILEDIR=$(TRUNKDIR)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : C_INCLUDE_PATH=$(TRUNKDIR):..:$(C_INCLUDE_PATH)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : LIBRARY_PATH=$(%LIBRARY_PATH)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(TRUNKDIR)/tests/lib818.dll
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(TRUNKDIR)/tests/ecp.dat
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(BUILDDIR)/$(EEXU) $(BUILDDIR)/$(EUBIND)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EECU)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(BUILDDIR)/$(LIBRARY_NAME)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html : $(TRUNKDIR)/tests/return15$(EXE_EXT)
$(BUILDDIR)/test-report.txt $(BUILDDIR)/test-report.html :

	-cd $(TRUNKDIR)/tests && rm ctc.log; EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(CYPTRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex $(CYPINCDIR) -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind "$(CYPBUILDDIR)/$(EUBIND)" -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		-log $(TESTFILE) ; \
	$(EXE) -i $(CYPTRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex -exe "$(CYPBUILDDIR)/$(EEXU)" -process-log  > $(CYPBUILDDIR)/test-report.txt ; \
	$(EXE) -i $(CYPTRUNKDIR)/include $(TRUNKDIR)/source/eutest.ex -eui "$(CYPBUILDDIR)/$(EEXU)" -process-log -html -css-file $(CYPBUILDDIR)/eutest.css > $(CYPBUILDDIR)/test-report.html
	cd $(TRUNKDIR)/tests && sh check_diffs.sh

testeu : $(TRUNKDIR)/tests/lib818.dll
testeu :
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) $(EXE) $(TRUNKDIR)/source/eutest.ex --nocheck -i $(TRUNKDIR)/include -cc gcc -exe "$(CYPBUILDDIR)/$(EEXU) -batch $(CYPTRUNKDIR)/source/eu.ex" $(TESTFILE)

test-311 :
	cd $(TRUNKDIR)/tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind $(CYPBUILDDIR)/$(EUBIND) -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		$(TESTFILE)

coverage-311 :
	cd $(TRUNKDIR)/tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test-311.edb -coverage $(CYPTRUNKDIR)/include \
		-coverage-exclude std -coverage-exclude euphoria \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage :  $(TRUNKDIR)/tests/lib818.dll
coverage :
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test.edb -coverage $(CYPTRUNKDIR)/include/std \
		-verbose \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage-front-end :  $(TRUNKDIR)/tests/lib818.dll
coverage-front-end :
	-rm $(CYPBUILDDIR)/front-end.edb
	cd $(TRUNKDIR)/tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i $(TRUNKDIR)/include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU) -coverage-db $(CYPBUILDDIR)/front-end.edb -coverage $(CYPTRUNKDIR)/source $(CYPTRUNKDIR)/source/eu.ex" \
		-verbose $(TESTFILE)
	eucoverage $(CYPBUILDDIR)/front-end.edb

.PHONY : coverage

ifeq "$(PREFIX)" ""
PREFIX=/usr/local
endif

install :
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria/debug
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/preproc
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/win32
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/tutorial
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/bin
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/source
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUDBGA) $(DESTDIR)$(PREFIX)/lib
ifneq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EECUSOA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUSODBGA) $(DESTDIR)$(PREFIX)/lib
endif
	install $(BUILDDIR)/$(EEXU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EECU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EBACKENDC) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUBIND) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUSHROUD) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUTEST) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUDIS) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUDIST) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUCOVERAGE) $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TRUNKDIR)/bin/*.ex $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TRUNKDIR)/bin/ecp.dat $(DESTDIR)$(PREFIX)/bin
ifeq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EBACKENDW) $(DESTDIR)$(PREFIX)/bin
endif
	install $(TRUNKDIR)/include/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include
	install $(TRUNKDIR)/include/std/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std
	install $(TRUNKDIR)/include/std/net/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	install $(TRUNKDIR)/include/std/win32/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	install $(TRUNKDIR)/include/euphoria/*.e  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	install $(TRUNKDIR)/include/euphoria/debug/*.e  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria/debug
	install $(TRUNKDIR)/include/euphoria.h $(DESTDIR)$(PREFIX)/share/euphoria/include
	install $(TRUNKDIR)/demo/*.e* $(DESTDIR)$(PREFIX)/share/euphoria/demo
	install $(TRUNKDIR)/demo/bench/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench
	install $(TRUNKDIR)/demo/langwar/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar
	install $(TRUNKDIR)/demo/unix/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	install $(TRUNKDIR)/demo/net/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	install $(TRUNKDIR)/demo/preproc/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/preproc
	install $(TRUNKDIR)/tutorial/* $(DESTDIR)$(PREFIX)/share/euphoria/tutorial
	install  \
	           $(TRUNKDIR)/bin/edx.ex \
	           $(TRUNKDIR)/bin/bugreport.ex \
	           $(TRUNKDIR)/bin/buildcpdb.ex \
	           $(TRUNKDIR)/bin/ecp.dat \
	           $(TRUNKDIR)/bin/eucoverage.ex \
	           $(TRUNKDIR)/bin/euloc.ex \
	           $(DESTDIR)$(PREFIX)/share/euphoria/bin
	install  \
	           $(TRUNKDIR)/source/*.ex \
	           $(TRUNKDIR)/source/*.e \
	           $(TRUNKDIR)/source/be_*.c \
                   $(TRUNKDIR)/source/*.h \
	           $(DESTDIR)$(PREFIX)/share/euphoria/source

EUDIS=eudis$(EXE_EXT)
EUTEST=eutest$(EXE_EXT)
EUCOVERAGE=eucoverage$(EXE_EXT)
EUDIST=eudist$(EXE_EXT)

ifeq "$(EMINGW)" "1"
	MINGW_FLAGS=-gcc -con
else
	MINGW_FLAGS=
endif

ifeq "$(ARCH)" "ARM"
	EUC_CFLAGS=-cflags "-fomit-frame-pointer -c -w -fsigned-char -I$(TRUNKDIR) -ffast-math"
	EUC_LFLAGS=-lflags "$(CYPBUILDDIR)/eu.a -ldl -lm -lpthread"
else
	EUC_CFLAGS=-cflags "$(FE_FLAGS)"
	EUC_LFLAGS=
endif


$(BUILDDIR)/eudist-build/main-.c : $(TRUNKDIR)/source/eudist.ex
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/eudist-build" -c "$(BUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUDIST)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(TRUNKDIR)/source/eudist.ex

$(BUILDDIR)/$(EUDIST) : $(TRUNKDIR)/source/eudist.ex $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA) $(BUILDDIR)/eudist-build/main-.c | $(BUILDDIR)
	$(MAKE) -C "$(BUILDDIR)/eudist-build" -f eudist.mak


$(BUILDDIR)/eudis-build/main-.c : $(TRUNKDIR)/source/dis.ex  $(TRUNKDIR)/source/dis.e $(TRUNKDIR)/source/dox.e
$(BUILDDIR)/eudis-build/main-.c : $(EU_CORE_FILES)
$(BUILDDIR)/eudis-build/main-.c : $(EU_INTERPRETER_FILES)
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/eudis-build" -c "$(CYPBUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUDIS)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(CYPTRUNKDIR)/source/dis.ex

$(BUILDDIR)/$(EUDIS) : $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA) $(BUILDDIR)/eudis-build/main-.c  $(BUILDDIR)/$(EECUA)
	$(MAKE) -C "$(BUILDDIR)/eudis-build" -f dis.mak


$(BUILDDIR)/bind-build/main-.c : $(TRUNKDIR)/source/eubind.ex $(EU_INTERPRETER_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/bind-build" -c "$(CYPBUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUBIND)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(CYPTRUNKDIR)/source/eubind.ex

$(BUILDDIR)/$(EUBIND) : $(BUILDDIR)/bind-build/main-.c $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA)
	$(MAKE) -C "$(CYPBUILDDIR)/bind-build" -f eubind.mak


$(BUILDDIR)/shroud-build/main-.c : $(TRUNKDIR)/source/eushroud.ex $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/shroud-build" -c "$(CYPBUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUSHROUD)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(CYPTRUNKDIR)/source/eushroud.ex

$(BUILDDIR)/$(EUSHROUD) : $(BUILDDIR)/shroud-build/main-.c $(BUILDDIR)/$(EECUA)
	$(MAKE) -C "$(CYPBUILDDIR)/shroud-build" -f eushroud.mak


$(BUILDDIR)/eutest-build/main-.c : $(TRUNKDIR)/source/eutest.ex
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/eutest-build" -c "$(CYPBUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUTEST)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(CYPTRUNKDIR)/source/eutest.ex

$(BUILDDIR)/$(EUTEST) : $(BUILDDIR)/eutest-build/main-.c  $(BUILDDIR)/$(EECUA)
	$(MAKE) -C "$(BUILDDIR)/eutest-build" -f eutest.mak


$(BUILDDIR)/eucoverage-build/main-.c : $(TRUNKDIR)/bin/eucoverage.ex
	$(TRANSLATE) -arch $(TARCH_FLAG) -build-dir "$(CYPBUILDDIR)/eucoverage-build" -c "$(CYPBUILDDIR)/eu.cfg" -o "$(CYPBUILDDIR)/$(EUCOVERAGE)" -lib "$(CYPBUILDDIR)/eu.a" \
		-silent -makefile -eudir $(CYPTRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) $(MINGW_FLAGS) $(CYPTRUNKDIR)/bin/eucoverage.ex

$(BUILDDIR)/$(EUCOVERAGE) : $(BUILDDIR)/eucoverage-build/main-.c $(BUILDDIR)/$(EECUA)
	$(MAKE) -C "$(CYPBUILDDIR)/eucoverage-build" -f eucoverage.mak


EU_TOOLS= \
	$(BUILDDIR)/$(EUDIST) \
	$(BUILDDIR)/$(EUDIS) \
	$(BUILDDIR)/$(EUTEST) \
	$(BUILDDIR)/$(EUBIND) \
	$(BUILDDIR)/$(EUSHROUD) \
	$(BUILDDIR)/$(EUCOVERAGE)

tools : $(EU_TOOLS)

clean-tools :
	-rm $(EU_TOOLS)

install-tools :
	install $(BUILDDIR)/$(EUDIST) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUDIS) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUTEST) $(DESTDIR)$(PREFIX)/bin/
	install $(BUILDDIR)/$(EUCOVERAGE) $(DESTDIR)$(PREFIX)/bin/

install-docs :
	# create dirs
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js
	install -d $(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install $(BUILDDIR)/euphoria.pdf $(DESTDIR)$(PREFIX)/share/doc/euphoria/
	install  \
		$(BUILDDIR)/html/*html \
		$(BUILDDIR)/html/*css \
		$(BUILDDIR)/html/search.dat \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html
	install  \
		$(BUILDDIR)/html/images/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install  \
		$(BUILDDIR)/html/js/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js


# This doesn't seem right. What about eushroud ?
uninstall :
	-rm $(PREFIX)/bin/$(EEXU) $(PREFIX)/bin/$(EECU) $(PREFIX)/lib/$(EECUA) $(PREFIX)/lib/$(EECUDBGA) $(PREFIX)/bin/$(EBACKENDC)
ifeq "$(EMINGW)" "1"
	-rm $(PREFIX)/lib/$(EBACKENDW)
endif
	-rm -r $(PREFIX)/share/euphoria

uninstall-docs :
	-rm -rf $(PREFIX)/share/doc/euphoria

.PHONY : install install-docs install-tools
.PHONY : uninstall uninstall-docs

ifeq "$(EUPHORIA)" "1"
$(BUILDDIR)/intobj/main-.c : $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/transobj/main-.c : $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/backobj/main-.c : $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
endif

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@

$(BUILDDIR)/%.res : $(TRUNKDIR)/source/%.rc
	$(RC) $< -O coff -o $@

$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o

ifneq "$(ARCH)" "ARM"
LIB818_FPIC=-fPIC
endif

$(BUILDDIR)/test818.o : test818.c
	$(CC) -c $(LIB818_FPIC) -I $(TRUNKDIR)/include $(FE_FLAGS) -Wall -shared $(TRUNKDIR)/source/test818.c -o $(BUILDDIR)/test818.o

$(TRUNKDIR)/tests/return15$(EXE_EXT) : return15.c
	$(CC)  $(TRUNKDIR)/source/return15.c $(MSIZE) -o $(TRUNKDIR)/tests/return15$(EXE_EXT)


lib818 :
	touch test818.c
	$(MAKE) $(TRUNKDIR)/tests/lib818.dll

testaux : $(TRUNKDIR)/tests/return15$(EXE_EXT) $(TRUNKDIR)/tests/lib818.dll

$(TRUNKDIR)/tests/lib818.dll : $(BUILDDIR)/test818.o
	$(CC)  $(MSIZE) $(LIB818_FPIC) -shared -o $(TRUNKDIR)/tests/lib818.dll $(CREATEDLLFLAGS) $(BUILDDIR)/test818.o

ifeq "$(EUPHORIA)" "1"

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN) | $(BUILDDIR)/$(OBJDIR)
	@echo $(TRANSLATE) -arch $(TARCH_FLAG) -silent -nobuild $(CYPINCDIR) -$(XLTTARGETCC) $(RELEASE_FLAG) $(TARGETPLAT) -c "$(BUILDDIR)/eu.cfg" $(CYPTRUNKDIR)/source/$(EU_TARGET)
	@(cd $(BUILDDIR)/$(OBJDIR); rm -f *.[co]; $(TRANSLATE) -arch $(TARCH_FLAG) -silent -nobuild $(CYPINCDIR) -$(XLTTARGETCC) $(RELEASE_FLAG) $(TARGETPLAT) -c "$(BUILDDIR)/eu.cfg" $(CYPTRUNKDIR)/source/$(EU_TARGET))
else
$(BUILDDIR)/intobj/main-.c : $(EU_MAIN)
	$(MAKE) $(BUILDDIR)/intobj/main-.c OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

$(BUILDDIR)/transobj/main-.c : $(EU_MAIN)
	$(MAKE) $(BUILDDIR)/transobj/main-.c OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

$(BUILDDIR)/backobj/main-.c : $(EU_MAIN)
	$(MAKE) $(BUILDDIR)/backobj/main-.c OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

endif
endif

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/%.o : $(TRUNKDIR)/source/%.c $(CONFIG_FILE) | $(BUILDDIR)/$(OBJDIR)/back/
	$(CC) $(BE_FLAGS) $(EBSDFLAG) -I $(BUILDDIR)/$(OBJDIR)/back -I $(BUILDDIR)/include $(TRUNKDIR)/source/$*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : $(TRUNKDIR)/source/$(BE_CALLC).c $(CONFIG_FILE) | $(BUILDDIR)/$(OBJDIR)/back/
	$(CC) -c -Wall $(EOSTYPE) $(ARCH_FLAG) $(FPIC) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -DARCH=$(ARCH) -fsigned-char $(OPT) -fno-omit-frame-pointer -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(TRUNKDIR)/source/$(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.o

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : $(TRUNKDIR)/source/be_inline.c $(CONFIG_FILE) | $(BUILDDIR)/$(OBJDIR)/back/
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) $(TRUNKDIR)/source/be_inline.c -o$(BUILDDIR)/$(OBJDIR)/back/be_inline.o
endif
ifdef PCRE_OBJECTS
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,$(TRUNKDIR)/source/pcre/%.c,$(PCRE_OBJECTS)) $(TRUNKDIR)/source/pcre/config.h.unix $(TRUNKDIR)/source/pcre/pcre.h.unix
	$(MAKE) -C $(TRUNKDIR)/source/pcre all CC="$(PCRE_CC)" PCRE_CC="$(PCRE_CC)" EOSTYPE="$(EOSTYPE)" EOSFLAGS="$(EOSPCREFLAGS)" FPIC=$(FPIC)
endif

.IGNORE : test

depend :
	cd $(TRUNKDIR)/source && ./depend.sh

# The dependencies below are automatically generated using the depend target above.
# DO NOT DELETE


$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/intobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_decompress.o: $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/intobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/intobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_runtime.o: $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/intobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/intobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/intobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/intobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/intobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/transobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/be_debug.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_debug.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/transobj/back/be_decompress.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/transobj/back/be_machine.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/transobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/transobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h
$(BUILDDIR)/transobj/back/be_runtime.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/transobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/transobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/transobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/transobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/backobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/backobj/back/be_decompress.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/backobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/backobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h
$(BUILDDIR)/backobj/back/be_runtime.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/backobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/backobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/backobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/backobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/backobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h

$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_alloc.o: $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_callc.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_coverage.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/global.h
$(BUILDDIR)/libobj/back/be_coverage.o: $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/redef.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_debug.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(BUILDDIR)/libobj/back/ $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_decompress.o: $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_decompress.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_inline.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_execute.o: $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_inline.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_inline.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/version.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_main.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/libobj/back/be_machine.o: $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_main.o: $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_pcre.h $(TRUNKDIR)/source/pcre/pcre.h
$(BUILDDIR)/libobj/back/be_pcre.o: $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_rterror.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h $(TRUNKDIR)/source/be_w.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_syncolor.h $(TRUNKDIR)/source/be_debug.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_inline.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_callc.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_coverage.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_runtime.o: $(TRUNKDIR)/source/be_symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/be_socket.o: $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_socket.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_symtab.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_runtime.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/reswords.h
$(BUILDDIR)/libobj/back/be_syncolor.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_syncolor.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h $(TRUNKDIR)/source/execute.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_task.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/be_alloc.h $(TRUNKDIR)/source/be_machine.h $(TRUNKDIR)/source/be_execute.h
$(BUILDDIR)/libobj/back/be_task.o: $(TRUNKDIR)/source/be_symtab.h $(TRUNKDIR)/source/alldefs.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/alldefs.h $(TRUNKDIR)/source/global.h $(TRUNKDIR)/source/object.h $(TRUNKDIR)/source/symtab.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/execute.h $(TRUNKDIR)/source/reswords.h $(TRUNKDIR)/source/be_w.h $(TRUNKDIR)/source/be_machine.h
$(BUILDDIR)/libobj/back/be_w.o: $(TRUNKDIR)/source/be_runtime.h $(TRUNKDIR)/source/be_rterror.h $(TRUNKDIR)/source/be_alloc.h
$(BUILDDIR)/libobj/back/echoversion.o: $(TRUNKDIR)/source/version.h
$(BUILDDIR)/libobj/back/rbt.o: $(TRUNKDIR)/source/rbt.h
