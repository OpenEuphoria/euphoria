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

CONFIG_FILE = config.gnu

ifndef CONFIG
CONFIG = $(CONFIG_FILE)
endif

PCRE_CC=$(CC)

include $(CONFIG)
include $(TRUNKDIR)/source/pcre/objects.mak

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
  LDLFLAG=-ldl -lresolv -lnsl
  PREREGEX=$(FROMBSDREGEX)
  SEDFLAG=-ri
endif
ifeq "$(EMINGW)" "1"
	EXE_EXT=.exe
	EPTHREAD=
	EOSTYPE=-DEWINDOWS
	EBSDFLAG=-DEMINGW
	LDLFLAG=
	SEDFLAG=-ri
	EOSFLAGS=$(NO_CYGWIN) -mwindows
	EOSFLAGSCONSOLE=$(NO_CYGWIN)
	EOSPCREFLAGS=$(NO_CYGWIN)
	EECUA=eu.a
	EECUDBGA=eudbg.a
	ifdef EDEBUG
		EOSMING=
		LIBRARY_NAME=eudbg.a
	else
		EOSMING=-ffast-math -O3 -Os
		LIBRARY_NAME=eu.a
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
	PCRE_CC=gcc
else
	EXE_EXT=
	EPTHREAD=-pthread
	EOSTYPE=-DEUNIX
	EOSFLAGS=
	EOSFLAGSCONSOLE=
	EOSPCREFLAGS=
	EECUA=eu.a
	EECUDBGA=eudbg.a
	ifdef EDEBUG
		LIBRARY_NAME=eudbg.a
	else
		EOSMING=-ffast-math -O3 -Os
		LIBRARY_NAME=eu.a
	endif
	MEM_FLAGS=-DESIMPLE_MALLOC
	
endif

ifeq "$(ARCH)" "ix86"
	# Mostly for OSX, but prevents bad conversions double<-->long
	# See ticket #874
	FP_FLAGS=-mno-sse
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
EEXUW=euiw$(EXE_EXT)

LDLFLAG+= $(EPTHREAD)

ifdef EDEBUG
DEBUG_FLAGS=-g3 -O0 -Wall
CALLC_DEBUG=-g3
EC_DEBUG=-D DEBUG
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
EXE=eui
else
EXE=$(EUBIN)/eui
endif
# The -i command with the include directory in the form we need the EUPHORIA binaries to see them. 
# (Use a drive id 'C:')
# [Which on Windows is different from the how it is expressed in for the GNU binaries. ]
CYPINCDIR=-i $(CYPTRUNKDIR)/include

BE_CALLC = be_callc


ifndef ECHO
ECHO=/bin/echo
endif

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
	TRANSLATE=$(EXE) $(CYPINCDIR) $(EC_DEBUG) $(CYPTRUNKDIR)/source/ec.ex
endif

ifeq "$(MANAGED_MEM)" "1"
FE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -fsigned-char $(EOSMING) -ffast-math $(FP_FLAGS) $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/ $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(MEM_FLAGS)
else
FE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -fsigned-char $(EOSMING) -ffast-math $(FP_FLAGS) $(EOSFLAGS) $(DEBUG_FLAGS) -I../ -I../../include/ $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE)
endif
BE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -Wall $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(FP_FLAGS) $(DEBUG_FLAGS) $(MEM_FLAGS) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE)

EU_CORE_FILES = \
	block.e \
	common.e \
	coverage.e \
	emit.e \
	error.e \
	fenv.e \
	fwdref.e \
	inline.e \
	keylist.e \
	main.e \
	msgtext.e \
	mode.e \
	opnames.e \
	parser.e \
	pathopen.e \
	platform.e \
	preproc.e \
	reswords.e \
	scanner.e \
	scinot.e \
	shift.e \
	symtab.e 

EU_INTERPRETER_FILES = \
	backend.e \
	c_out.e \
	cominit.e \
	compress.e \
	global.e \
	intinit.e \
	int.ex

EU_TRANSLATOR_FILES = \
	buildsys.e \
	c_decl.e \
	c_out.e \
	cominit.e \
	compile.e \
	compress.e \
	global.e \
	traninit.e \
	ec.ex

EU_BACKEND_RUNNER_FILES = \
	backend.e \
	il.e \
	cominit.e \
	compress.e \
	error.e \
	intinit.e \
	mode.e \
	reswords.e \
	pathopen.e \
	common.e \
	backend.ex

PREFIXED_PCRE_OBJECTS = $(addprefix $(BUILDDIR)/pcre/,$(PCRE_OBJECTS))
	
EU_BACKEND_OBJECTS = \
	$(BUILDDIR)/$(OBJDIR)/back/be_decompress.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_execute.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_main.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_machine.o \
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
	$(BUILDDIR)/$(OBJDIR)/back/be_w.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_alloc.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_inline.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_pcre.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_socket.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_runtime.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_task.o \
	$(BUILDDIR)/$(OBJDIR)/back/be_callc.o \
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
	$(wildcard $(TRUNKDIR)/demo/*.ex) \
	$(wildcard $(TRUNKDIR)/demo/win32/*.ew) \
	$(wildcard $(TRUNKDIR)/demo/bench/*.ex) \
	$(wildcard $(TRUNKDIR)/demo/net/*.ex) \
	$(wildcard $(TRUNKDIR)/demo/preproc/*.ex) \
	$(wildcard $(TRUNKDIR)/demo/unix/*.ex) \
	$(wildcard $(DOCDIR)/*.txt) \
	$(wildcard $(DOCDIR)/release/*.txt)

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all : 
	$(MAKE) code-page-db interpreter translator library debug-library backend
	$(MAKE) tools


BUILD_DIRS=\
	$(BUILDDIR)/intobj/back/ \
	$(BUILDDIR)/transobj/back/ \
	$(BUILDDIR)/libobj/back/ \
	$(BUILDDIR)/libobjdbg \
	$(BUILDDIR)/libobjdbg/back/ \
	$(BUILDDIR)/backobj/back/ \
	$(BUILDDIR)/intobj/ \
	$(BUILDDIR)/transobj/ \
	$(BUILDDIR)/libobj/ \
	$(BUILDDIR)/backobj/ \
	$(BUILDDIR)/include/


clean : 	
	-for f in $(BUILD_DIRS) ; do \
		rm -r $${f} ; \
	done ;
	-rm -r $(BUILDDIR)/pcre
	-rm -r $(BUILDDIR)/pdf
	-rm -r $(BUILDDIR)/*-build
	-rm $(BUILDDIR)/eui$(EXE_EXT) $(BUILDDIR)/$(EEXUW)
	-rm $(BUILDDIR)/$(EECU)
	-rm $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW)
	-rm $(BUILDDIR)/eu.a
	-rm $(BUILDDIR)/eudbg.a
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

	$(MAKE) -C pcre CONFIG=../$(CONFIG) clean
	

.PHONY : clean distclean clobber all htmldoc manual

ifndef OBJDIR
$(BUILDDIR)/$(EECUDBGA) : $(wildcard $(TRUNKDIR)/source/*.[ch]) $(wildcard $(TRUNKDIR)/source/pcre/*.[ch]) | $(BUILD_DIRS)
	$(MAKE) $(BUILDDIR)/$(EECUDBGA) OBJDIR=libobjdbg ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE)

$(BUILDDIR)/$(EECUA) : $(wildcard $(TRUNKDIR)/source/*.{c,h}) $(wildcard $(TRUNKDIR)/source/pcre/*.{c,h}) | $(BUILD_DIRS)
	$(MAKE) $(BUILDDIR)/$(EECUA) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG= EPROFILE=$(EPROFILE)
else
$(BUILDDIR)/$(LIBRARY_NAME) : $(EU_LIB_OBJECTS)
	ar -rc $(BUILDDIR)/$(LIBRARY_NAME) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)
endif

debug-library : $(BUILDDIR)/$(EECUDBGA)

library : $(BUILDDIR)/$(EECUA)

builddirs : | $(BUILD_DIRS)

$(BUILD_DIRS) :
	mkdir -p $(BUILD_DIRS) 

ifeq "$(ROOTDIR)" ""
ROOTDIR=$(TRUNKDIR)
endif

code-page-db : $(BUILDDIR)/ecp.dat $(TRUNKDIR)/tests/ecp.dat

$(BUILDDIR)/ecp.dat : $(TRUNKDIR)/source/codepage/*.ecp msgtext.e $(BUILDDIR)/$(EEXU)
	$(BUILDDIR)/$(EEXU) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/buildcpdb.ex -p$(CYPTRUNKDIR)/source/codepage -o$(CYPBUILDDIR)

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


euisource : $(BUILDDIR)/intobj/main-.c
euisource :  EU_TARGET = int.ex
euisource : $(BUILDDIR)/intobj/back/coverage.h

eucsource : $(BUILDDIR)/transobj/main-.c
eucsource :  EU_TARGET = ec.ex
eucsource : $(BUILDDIR)/transobj/back/coverage.h

backendsource : $(BUILDDIR)/backobj/main-.c
backendsource :  EU_TARGET=backend.ex
backendsource : $(BUILDDIR)/backobj/back/coverage.h

source : | $(BUILD_DIRS)
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

HASH := $(shell git show --format='%H' | head -1)
SHORT_HASH := $(shell git show --format='%h' | head -1)

ifneq "$(VERSION)" ""
SOURCEDIR=euphoria-$(PLAT)-$(VERSION)
else

ifeq "$(PLAT)" ""
SOURCEDIR=euphoria-$(SHORT_HASH)
else
SOURCEDIR=euphoria-$(PLAT)-$(SHORT_HASH)
endif

endif

source-tarball : $(BUILDDIR)/$(SOURCEDIR)-src.tar.gz

$(BUILDDIR)/$(SOURCEDIR)-src.tar.gz : $(MKVER) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_INTERPRETER_FILES) $(EU_CORE_FILES) $(EU_STD_INC) $(wildcard *.c) $(BUILDDIR)/intobj/main-.c $(BUILDDIR)/transobj/main-.c $(BUILDDIR)/backobj/main-.c
	echo building source-tarball for $(PLAT)
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

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/coverage.h : $(BUILDDIR)/$(OBJDIR)/main-.c
	$(EXE) -i $(CYPTRUNKDIR)/include coverage.ex $(CYPBUILDDIR)/$(OBJDIR)
else
$(BUILDDIR)/intobj/back/coverage.h : | $(BUILD_DIRS)
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

$(BUILDDIR)/transobj/back/coverage.h : | $(BUILD_DIRS)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

$(BUILDDIR)/backobj/back/coverage.h : | $(BUILD_DIRS)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif
	
$(BUILDDIR)/intobj/back/be_execute.o : $(BUILDDIR)/intobj/back/coverage.h
$(BUILDDIR)/transobj/back/be_execute.o : $(BUILDDIR)/transobj/back/coverage.h
$(BUILDDIR)/backobj/back/be_execute.o : $(BUILDDIR)/backobj/back/coverage.h

$(BUILDDIR)/intobj/back/be_runtime.o : $(BUILDDIR)/intobj/back/coverage.h
$(BUILDDIR)/transobj/back/be_runtime.o : $(BUILDDIR)/transobj/back/coverage.h
$(BUILDDIR)/backobj/back/be_runtime.o : $(BUILDDIR)/backobj/back/coverage.h

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/be_machine.o : $(BUILDDIR)/include/be_ver.h
endif

ifeq "$(EMINGW)" "1"
$(EUI_RES) : eui.rc version_info.rc eu.manifest
$(EUIW_RES) : euiw.rc version_info.rc eu.manifest
endif

$(BUILDDIR)/$(EEXU) :  EU_TARGET = int.ex
$(BUILDDIR)/$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EEXU) :  $(wildcard $(BUILDDIR)/intobj/*.c) $(EU_MAIN) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES) $(wildcard be_*.c)
$(BUILDDIR)/$(EEXU) :  $(BUILDDIR)/include/be_ver.h $(TRUNKDIR)/source/pcre/*.c
ifeq "$(OBJDIR)" "intobj"
$(BUILDDIR)/$(EEXU) :  EU_OBJS="$(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EUI_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EUIW_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
endif
else
$(BUILDDIR)/$(EEXU) : | $(BUILDDIR)/intobj
ifeq "$(EUPHORIA)" "1"
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif


$(BUILDDIR)/$(OBJDIR)/back/be_machine.o : $(BUILDDIR)/include/be_ver.h

ifeq "$(EMINGW)" "1"
$(EUC_RES) :  $(TRUNKDIR)/source/euc.rc  $(TRUNKDIR)/source/version_info.rc  $(TRUNKDIR)/source/eu.manifest
endif

$(BUILDDIR)/$(EECU) :  EU_TARGET = euc.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EECU) :  $(wildcard $(BUILDDIR)/transobj/*.c) $(EU_MAIN) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES) $(wildcard be_*.c)
$(BUILDDIR)/$(EECU) :  $(TRUNKDIR)/source/pcre/*.c
ifeq "$(OBJDIR)" "transobj"
$(BUILDDIR)/$(EECU) :  EU_OBJS="$(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EECU) :  $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
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

$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_TARGET = backend.ex
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_MAIN = $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES)  $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(wildcard $(BUILDDIR)/backobj/*.c) $(EU_MAIN)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(TRUNKDIR)/source/pcre/*.c
ifeq "$(OBJDIR)" "backobj"
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  EU_OBJS="$(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)"
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(PREFIXED_PCRE_OBJECTS)
$(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EBACKENDW) :  $(EUB_RES) $(EUBW_RES)
	@$(ECHO) making $(EBACKENDC)
	$(CC) $(EOSFLAGS) $(EUB_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EBACKENDC)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGS) $(EUBW_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EBACKENDW)
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

$(MKVER): mkver.c
	$(CC) -o $@ $<
	
$(BUILDDIR)/include:
	mkdir $@


$(BUILDDIR)/include/be_ver.h $(BUILDDIR)/ver.cache : $(MKVER) $(BUILDDIR)/include $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_INTERPRETER_FILES) $(EU_CORE_FILES) $(EU_STD_INC) $(wildcard *.c)  
	$(MKVER) "$(HG)" "$(BUILDDIR)/ver.cache" "$(BUILDDIR)/include/be_ver.h" $(EREL_TYPE)$(RELEASE)


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
	$(EUDOC) -d PDF --single --strip=2 -a $(TRUNKDIR)/docs/manual.af -o $(BUILDDIR)/pdf/euphoria.txt

$(BUILDDIR)/pdf/euphoria.tex : $(BUILDDIR)/pdf/euphoria.txt $(TRUNKDIR)/docs/template.tex
	cd $(TRUNKDIR)/docs && $(CREOLE) -f latex -A -t=$(TRUNKDIR)/docs/template.tex -o=$(BUILDDIR)/pdf $<

$(BUILDDIR)/euphoria.pdf : $(BUILDDIR)/pdf/euphoria.tex
	cd $(TRUNKDIR)/docs && pdflatex -output-directory=$(BUILDDIR)/pdf $(BUILDDIR)/pdf/euphoria.tex && cp $(BUILDDIR)/pdf/euphoria.pdf $(BUILDDIR)/
	
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
	$(EUDOC) --single --verbose --test-eucode --work-dir=$(BUILDDIR)/eudoc_test -o $(BUILDDIR)/test_eucode.txt $(EU_STD_INC)
	$(CREOLE) -o $(BUILDDIR) $(BUILDDIR)/test_eucode.txt

#
# Unit Testing
#

test : EUDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)
test : EUCOMPILEDIR=$(TRUNKDIR)	
test : C_INCLUDE_PATH=$(TRUNKDIR):..:$(C_INCLUDE_PATH)
test : LIBRARY_PATH=$(%LIBRARY_PATH)
test : ../tests/lib818.dll $(TRUNKDIR)/tests/ecp.dat $(CYPBUILDDIR)/$(EEXU) $(BUILDDIR)/$(EUBIND) $(BUILDDIR)/$(EBACKENDC) $(BUILDDIR)/$(EECU) $(CYPBUILDDIR)/$(LIBRARY_NAME)
test :  
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include ../source/eutest.ex -i ../include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind "$(CYPBUILDDIR)/$(EUBIND)" -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		-log $(TESTFILE) ; \
	$(EXE) -i ../include ../source/eutest.ex -process-log > $(CYPBUILDDIR)/test-report.txt ; \
	$(EXE) -i ../include ../source/eutest.ex -process-log -html > $(CYPBUILDDIR)/test-report.html	
	cd ../tests && sh check_diffs.sh

testeu : ../tests/lib818.dll
testeu : 
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) $(EXE) ../source/eutest.ex --nocheck -i ../include -cc gcc -exe "$(CYPBUILDDIR)/$(EEXU) -batch $(CYPTRUNKDIR)/source/eu.ex" $(TESTFILE)

test-311 :
	cd ../tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind $(CYPTRUNKDIR)/source/bind.ex -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		$(TESTFILE)
		
coverage-311 :
	cd ../tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test-311.edb -coverage $(CYPTRUNKDIR)/include \
		-coverage-exclude std -coverage-exclude euphoria \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage :  ../tests/lib818.dll
coverage : 
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test.edb -coverage $(CYPTRUNKDIR)/include/std \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage-front-end :  ../tests/lib818.dll
coverage-front-end : 
	-rm $(CYPBUILDDIR)/front-end.edb
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU) -coverage-db $(CYPBUILDDIR)/front-end.edb -coverage $(CYPTRUNKDIR)/source $(CYPTRUNKDIR)/source/eu.ex" \
		-verbose $(TESTFILE)
	eucoverage $(CYPBUILDDIR)/front-end.edb

.PHONY : coverage

ifeq "$(PREFIX)" ""
PREFIX=/usr/local
endif

install :
	mkdir -p $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
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
	install $(BUILDDIR)/$(EEXU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EECU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EBACKENDC) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUBIND) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUSHROUD) $(DESTDIR)$(PREFIX)/bin
	install -m 755 ../bin/*.ex $(DESTDIR)$(PREFIX)/bin
	install -m 755 ../bin/ecp.dat $(DESTDIR)$(PREFIX)/bin
ifeq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EBACKENDW) $(DESTDIR)$(PREFIX)/bin
endif
	install ../include/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include
	install ../include/std/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std
	install ../include/std/net/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/net
	install ../include/std/win32/*e  $(DESTDIR)$(PREFIX)/share/euphoria/include/std/win32
	install ../include/euphoria/*  $(DESTDIR)$(PREFIX)/share/euphoria/include/euphoria
	install ../include/euphoria.h $(DESTDIR)$(PREFIX)/share/euphoria/include
	install ../demo/*.e* $(DESTDIR)$(PREFIX)/share/euphoria/demo
	install ../demo/bench/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/bench 
	install ../demo/langwar/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/langwar
	install ../demo/unix/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/unix
	install ../demo/net/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/net
	install ../demo/preproc/* $(DESTDIR)$(PREFIX)/share/euphoria/demo/preproc
	install ../tutorial/* $(DESTDIR)$(PREFIX)/share/euphoria/tutorial
	install  \
	           ../bin/ed.ex \
	           ../bin/bugreport.ex \
	           ../bin/buildcpdb.ex \
	           ../bin/ecp.dat \
	           ../bin/eucoverage.ex \
	           ../bin/euloc.ex \
	           $(DESTDIR)$(PREFIX)/share/euphoria/bin
	install  \
	           *.ex \
	           *.e \
	           be_*.c \
	           *.h \
	           $(DESTDIR)$(PREFIX)/share/euphoria/source

EUDIS=eudis
EUTEST=eutest
EUCOVERAGE=eucoverage
EUDIST=eudist

$(BUILDDIR)/eudist-build/main-.c : eudist.ex
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eudist-build" \
		-o "$(BUILDDIR)/$(EUDIST)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/source/eudist.ex

$(BUILDDIR)/$(EUDIST) : $(TRUNKDIR)/source/eudist.ex $(BUILDDIR)/$(EECU)  $(BUILDDIR)/$(LIBRARY_NAME)  $(BUILDDIR)/eudist-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eudist-build" -f eudist.mak

$(BUILDDIR)/eudis-build/main-.c : $(TRUNKDIR)/source/dis.ex  $(TRUNKDIR)/source/dis.e $(TRUNKDIR)/source/dox.e
$(BUILDDIR)/eudis-build/main-.c : $(EU_CORE_FILES) 
$(BUILDDIR)/eudis-build/main-.c : $(EU_INTERPRETER_FILES) 
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eudis-build" \
		-o "$(BUILDDIR)/$(EUDIS)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/source/dis.ex

$(BUILDDIR)/$(EUDIS) : $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(EECUA) $(BUILDDIR)/eudis-build/main-.c  $(BUILDDIR)/$(LIBRARY_NAME)
		$(MAKE) -C "$(BUILDDIR)/eudis-build" -f dis.mak

$(BUILDDIR)/bind-build/main-.c : $(TRUNKDIR)/source/bind.ex $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/bind-build" \
		-o "$(BUILDDIR)/$(EUBIND)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/source/bind.ex

$(BUILDDIR)/$(EUBIND) : $(BUILDDIR)/bind-build/main-.c $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(LIBRARY_NAME) 
		$(MAKE) -C "$(BUILDDIR)/bind-build" -f bind.mak

$(BUILDDIR)/shroud-build/main-.c : $(TRUNKDIR)/source/shroud.ex $(EU_BACKEND_RUNNER_FILES) $(EU_CORE_FILES)
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/shroud-build" \
		-o "$(BUILDDIR)/$(EUSHROUD)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/source/shroud.ex

$(BUILDDIR)/$(EUSHROUD) : $(BUILDDIR)/shroud-build/main-.c $(BUILDDIR)/$(EECU) $(BUILDDIR)/$(LIBRARY_NAME) 
		$(MAKE) -C "$(BUILDDIR)/shroud-build" -f shroud.mak

$(BUILDDIR)/eutest-build/main-.c : $(TRUNKDIR)/source/eutest.ex 
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eutest-build" \
		-o "$(BUILDDIR)/$(EUTEST)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/source/eutest.ex

$(BUILDDIR)/$(EUTEST) : $(BUILDDIR)/eutest-build/main-.c $(BUILDDIR)/$(LIBRARY_NAME) 
		$(MAKE) -C "$(BUILDDIR)/eutest-build" -f eutest.mak

$(BUILDDIR)/eucoverage-build/main-.c : $(TRUNKDIR)/bin/eucoverage.ex $(EU_CORE_FILES) $(EU_INTERPRETER_FILES)
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eucoverage-build" \
		-o "$(BUILDDIR)/$(EUCOVERAGE)" \
		-makefile -eudir $(TRUNKDIR) \
		$(TRUNKDIR)/bin/eucoverage.ex

$(BUILDDIR)/$(EUCOVERAGE) : $(BUILDDIR)/eucoverage-build/main-.c $(BUILDDIR)/$(LIBRARY_NAME) 
		$(MAKE) -C "$(BUILDDIR)/eucoverage-build" -f eucoverage.mak

EU_TOOLS= $(BUILDDIR)/$(EUDIST) \
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
$(BUILDDIR)/intobj/main-.c : $(BUILDDIR)/include/be_ver.h $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/transobj/main-.c : $(BUILDDIR)/include/be_ver.h $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/backobj/main-.c : $(BUILDDIR)/include/be_ver.h $(EU_CORE_FILES) $(EU_BACKEND_RUNNER_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
endif

%obj :
	mkdir -p $@

%back : %
	mkdir -p $@

$(BUILDDIR)/%.res : %.rc
	windres $< -O coff -o $@

LIB818_FPIC=-fPIC

$(BUILDDIR)/test818.o : test818.c
	$(CC) -c $(LIB818_FPIC) -I ../include $(FE_FLAGS) -Wall -shared ../source/test818.c -o $(BUILDDIR)/test818.o

lib818 :
	touch test818.c
	$(MAKE) ../tests/lib818.dll

../tests/lib818.dll : $(BUILDDIR)/test818.o
	$(CC)  $(MSIZE) $(LIB818_FPIC) -shared -o ../tests/lib818.dll $(CREATEDLLFLAGS) $(BUILDDIR)/test818.o

ifneq "$(OBJDIR)" ""

$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o
else
$(BUILDDIR)/intobj/%.o : $(BUILDDIR)/intobj/%.c
	$(MAKE) OBJDIR=intobj $(BUILDDIR)/intobj/$*.o

$(BUILDDIR)/transobj/%.o : $(BUILDDIR)/transobj/%.c
	$(MAKE) OBJDIR=transobj $(BUILDDIR)/transobj/$*.o

$(BUILDDIR)/backobj/%.o : $(BUILDDIR)/backobj/%.c
	$(MAKE) OBJDIR=backobj $(BUILDDIR)/backobj/$*.o

	
endif

ifeq "$(EUPHORIA)" "1"
ifneq "$(OBJDIR)" ""

$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN) |  $(BUILDDIR)/$(OBJDIR)  $(BUILDDIR)/$(OBJDIR)/back
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	rm -f $(BUILDDIR)/$(OBJDIR)/{*.c,*.o}
	(cd $(BUILDDIR)/$(OBJDIR);$(TRANSLATE) -nobuild $(RELEASE_FLAG) \
		-c $(BUILDDIR)/eu.cfg $(CYPTRUNKDIR)/source/$(EU_TARGET) )


endif	
endif

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/%.o : %.c $(CONFIG_FILE)
	$(CC) $(BE_FLAGS) $(EBSDFLAG) -I $(BUILDDIR)/$(OBJDIR)/back -I $(BUILDDIR)/include $*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : ./$(BE_CALLC).c $(CONFIG_FILE)
	$(CC) -c -Wall $(EOSTYPE) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -fsigned-char -O3 -fno-omit-frame-pointer -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.o

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : ./be_inline.c $(CONFIG_FILE) 
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$(BUILDDIR)/$(OBJDIR)/back/be_inline.o
endif
ifdef PCRE_OBJECTS	
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,pcre/%.c,$(PCRE_OBJECTS)) pcre/config.h.unix pcre/pcre.h.unix
	$(MAKE) -C pcre all CC="$(PCRE_CC)" PCRE_CC="$(PCRE_CC)" EOSTYPE="$(EOSTYPE)" EOSFLAGS="$(EOSPCREFLAGS)" CONFIG=../$(CONFIG)
endif

.IGNORE : test

depend :
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/intobj/back/'
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/transobj/back/' -a
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/backobj/back/' -a
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/libobj/back/' -a

# The dependencies below are automatically generated using the depend target above.
# DO NOT DELETE

$(BUILDDIR)/intobj/back/be_alloc.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_alloc.o: be_alloc.h  execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_alloc.o: be_alloc.h  be_alloc.h
$(BUILDDIR)/intobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/intobj/back/be_decompress.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/intobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/intobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/intobj/back/be_execute.o: be_callc.h be_execute.h
$(BUILDDIR)/intobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/intobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/intobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/intobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/intobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/intobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/intobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/intobj/back/be_main.o: be_w.h
$(BUILDDIR)/intobj/back/be_pcre.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_pcre.o: be_alloc.h  execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_pcre.o: be_alloc.h  be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/intobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_alloc.h be_syncolor.h
$(BUILDDIR)/intobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_rterror.h be_execute.h be_symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_socket.o: be_runtime.h be_socket.h
$(BUILDDIR)/intobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/intobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/intobj/back/be_syncolor.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_syncolor.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_syncolor.o: be_w.h
$(BUILDDIR)/intobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/intobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/intobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/intobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/intobj/back/be_w.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_w.o: be_alloc.h  execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/intobj/back/be_w.o: be_alloc.h  be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/intobj/back/rbt.o: rbt.h

$(BUILDDIR)/transobj/back/be_alloc.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_alloc.o: be_alloc.h  execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_alloc.o: be_alloc.h  be_alloc.h
$(BUILDDIR)/transobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/transobj/back/be_decompress.o: alldefs.h global.h object.h
$(BUILDDIR)/transobj/back/be_decompress.o: symtab.h execute.h reswords.h
$(BUILDDIR)/transobj/back/be_decompress.o: be_alloc.h
$(BUILDDIR)/transobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/transobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/transobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/transobj/back/be_execute.o: be_callc.h be_execute.h
$(BUILDDIR)/transobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/transobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/transobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/transobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/transobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/transobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/transobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/transobj/back/be_main.o: be_w.h
$(BUILDDIR)/transobj/back/be_pcre.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_pcre.o: be_alloc.h  execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_pcre.o: be_alloc.h  be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/transobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_alloc.h be_syncolor.h
$(BUILDDIR)/transobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_rterror.h be_execute.h be_symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_socket.o: be_runtime.h be_socket.h
$(BUILDDIR)/transobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/transobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/transobj/back/be_syncolor.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_syncolor.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_syncolor.o: be_w.h
$(BUILDDIR)/transobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/transobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/transobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/transobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/transobj/back/be_w.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_w.o: be_alloc.h  execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/transobj/back/be_w.o: be_alloc.h  be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/transobj/back/rbt.o: rbt.h

$(BUILDDIR)/backobj/back/be_alloc.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_alloc.o: be_alloc.h  execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_alloc.o: be_alloc.h  be_alloc.h
$(BUILDDIR)/backobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/backobj/back/be_decompress.o: alldefs.h global.h object.h
$(BUILDDIR)/backobj/back/be_decompress.o: symtab.h execute.h reswords.h
$(BUILDDIR)/backobj/back/be_decompress.o: be_alloc.h
$(BUILDDIR)/backobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/backobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/backobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/backobj/back/be_execute.o: be_callc.h be_execute.h
$(BUILDDIR)/backobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/backobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/backobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/backobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/backobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/backobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/backobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/backobj/back/be_main.o: be_w.h
$(BUILDDIR)/backobj/back/be_pcre.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_pcre.o: be_alloc.h  execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_pcre.o: be_alloc.h  be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/backobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_alloc.h be_syncolor.h
$(BUILDDIR)/backobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_rterror.h be_execute.h be_symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_socket.o: be_runtime.h be_socket.h
$(BUILDDIR)/backobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/backobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/backobj/back/be_syncolor.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_syncolor.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_syncolor.o: be_w.h
$(BUILDDIR)/backobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/backobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/backobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/backobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/backobj/back/be_w.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_w.o: be_alloc.h  execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/backobj/back/be_w.o: be_alloc.h  be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/backobj/back/rbt.o: rbt.h

$(BUILDDIR)/libobj/back/be_alloc.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_alloc.o: be_alloc.h  execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_alloc.o: be_alloc.h  be_alloc.h
$(BUILDDIR)/libobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/libobj/back/be_decompress.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/libobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/libobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/libobj/back/be_execute.o: be_callc.h be_execute.h
$(BUILDDIR)/libobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/libobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/libobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/libobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/libobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/libobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/libobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/libobj/back/be_main.o: be_w.h
$(BUILDDIR)/libobj/back/be_pcre.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_pcre.o: be_alloc.h  execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_pcre.o: be_alloc.h  be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/libobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_alloc.h be_syncolor.h
$(BUILDDIR)/libobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_rterror.h be_execute.h be_symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_socket.o: be_runtime.h be_socket.h
$(BUILDDIR)/libobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/libobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/libobj/back/be_syncolor.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_syncolor.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_syncolor.o: be_w.h
$(BUILDDIR)/libobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/libobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/libobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/libobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/libobj/back/be_w.o: be_alloc.h  alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_w.o: be_alloc.h  execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/libobj/back/be_w.o: be_alloc.h  be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/libobj/back/rbt.o: rbt.h
