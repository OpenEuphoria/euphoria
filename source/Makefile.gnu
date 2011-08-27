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
	ifeq "$(EHOST)" "EWIN"
		HOST_EXE_EXT=.exe
	endif
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
		EOSMING=-ffast-math -O3 -Os
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
		ifdef FPIC
			LIBRARY_NAME=euso.a
		else
			LIBRARY_NAME=eu.a
		endif
	endif
	MEM_FLAGS=-DESIMPLE_MALLOC
endif

MKVER=$(BUILDDIR)/mkver$(EXE_EXT)
EBACKENDU=eub$(EXE_EXT)
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

ifeq  "$(EUBIN)" ""
EXE=$(EEXU)
HOST_EXE=$(HOST_EEXU)
else
EXE=$(EUBIN)/$(EEXU)
HOST_EXE=$(EUBIN)/$(HOST_EEXU)
endif
INCDIR=-i $(TRUNKDIR)/include
CYPINCDIR=-i $(CYPTRUNKDIR)/include

ifdef PLAT
TARGETPLAT=-plat $(PLAT)
endif

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
	TRANSLATE=$(EECU)
else
	TRANSLATE=$(HOST_EXE) $(CYPINCDIR) $(EC_DEBUG) $(EFLAG) $(CYPTRUNKDIR)/source/ec.ex
endif

ifeq "$(MANAGED_MEM)" "1"
FE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(MEM_FLAGS)
else
FE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -fsigned-char $(EOSTYPE) $(EOSMING) -ffast-math $(EOSFLAGS) $(DEBUG_FLAGS) -I$(CYPTRUNKDIR)/source -I$(CYPTRUNKDIR) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE)
endif
BE_FLAGS =  $(COVERAGEFLAG) $(MSIZE) $(EPTRHEAD) -c -Wall $(EOSTYPE) $(EBSDFLAG) $(RUNTIME_FLAGS) $(EOSFLAGS) $(BACKEND_FLAGS) -fsigned-char -ffast-math $(DEBUG_FLAGS) $(MEM_FLAGS) $(PROFILE_FLAGS) -DARCH=$(ARCH) $(EREL_TYPE) $(FPIC)

EU_CORE_FILES = \
	block.e \
	common.e \
	coverage.e \
	emit.e \
	error.e \
	fwdref.e \
	inline.e \
	keylist.e \
	main.e \
	memstruct.e \
	msgtext.e \
	mode.e \
	opnames.e \
	parser.e \
	pathopen.e \
	platform.e \
	preproc.e \
	reswords.e \
	scanner.e \
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
	$(BUILDDIR)/$(OBJDIR)/back/be_memstruct.o \
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
	$(PREFIXED_PCRE_OBJECTS)
	

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
	$(wildcard $(DOCDIR)/*.txt) \
	$(wildcard $(INCDIR)/euphoria/debug/*.e)

EU_TRANSLATOR_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/transobj/*.c))
EU_BACKEND_RUNNER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/backobj/*.c))
EU_INTERPRETER_OBJECTS = $(patsubst %.c,%.o,$(wildcard $(BUILDDIR)/intobj/*.c))

all : 
	$(MAKE) interpreter translator library debug-library backend shared-library debug-shared-library
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
	$(BUILDDIR)/include/ \
	$(BUILDDIR)/libobj-fPIC/ \
	$(BUILDDIR)/libobj-fPIC/back \
	$(BUILDDIR)/libobjdbg-fPIC \
	$(BUILDDIR)/libobjdbg-fPIC/back


clean : 	
	-for f in $(BUILD_DIRS) ; do \
		rm -r $${f} ; \
	done ;
	-rm -r $(BUILDDIR)/pcre
	-rm -r $(BUILDDIR)/pcre_fpic
	-rm $(BUILDDIR)/*pdf
	-rm $(BUILDDIR)/*txt
	-rm -r $(BUILDDIR)/*-build
	-rm $(BUILDDIR)/eui
	-rm $(BUILDDIR)/euc
	-rm $(BUILDDIR)/eub
	-rm $(BUILDDIR)/eu.a
	-rm $(BUILDDIR)/eudbg.a
	-rm $(BUILDDIR)/euso.a
	-for f in $(EU_TOOLS) ; do \
		rm $${f} ; \
	done ;
	-rm $(BUILDDIR)/ver.cache
	-rm $(BUILDDIR)/mkver
	-rm -r $(BUILDDIR)/html
	-rm -r $(BUILDDIR)/coverage
	-rm -r $(BUILDDIR)/manual
	

clobber distclean : clean
	-rm -f $(CONFIG)
	-rm -f Makefile
	-rm -fr $(BUILDDIR)
	-rm eu.cfg

ifeq "$(MINGW)" "1"
	-rm -f $(BUILDDIR)/{$(EBACKENDC),$(EEXUW)}
endif
	$(MAKE) -C pcre CONFIG=../$(CONFIG) clean
	$(MAKE) -C pcre CONFIG=../$(CONFIG) FPIC=-fPIC clean
	

.PHONY : clean distclean clobber all htmldoc manual

debug-library : builddirs
	$(MAKE) $(BUILDDIR)/$(EECUDBGA) OBJDIR=libobjdbg ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE)

library : builddirs
	$(MAKE) $(BUILDDIR)/$(LIBRARY_NAME) OBJDIR=libobj ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

shared-library :
	$(MAKE) $(BUILDDIR)/$(EECUSOA) OBJDIR=libobj-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE) FPIC=-fPIC

debug-shared-library : builddirs
	$(MAKE) $(BUILDDIR)/$(EECUSODBGA) OBJDIR=libobjdbg-fPIC ERUNTIME=1 CONFIG=$(CONFIG) EDEBUG=1 EPROFILE=$(EPROFILE) FPIC=-fPIC

$(BUILDDIR)/$(LIBRARY_NAME) : $(EU_LIB_OBJECTS)
	ar -rc $(BUILDDIR)/$(LIBRARY_NAME) $(EU_LIB_OBJECTS)
	$(ECHO) $(MAKEARGS)

builddirs : $(BUILD_DIRS)

$(BUILD_DIRS) :
	mkdir -p $(BUILD_DIRS) 

ifeq "$(ROOTDIR)" ""
ROOTDIR=$(TRUNKDIR)
endif

code-page-db : $(BUILDDIR)/ecp.dat

$(BUILDDIR)/ecp.dat : $(TRUNKDIR)/source/codepage/*.ecp
	$(BUILDDIR)/$(EEXU) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/buildcpdb.ex -p$(CYPTRUNKDIR)/source/codepage -o$(CYPBUILDDIR)

interpreter : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EEXU) OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

translator : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EECU) OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

EUBIND=eubind$(EXE_EXT)
EUSHROUD=eushroud$(EXE_EXT)

binder : translator library $(EU_BACKEND_RUNNER_FILES)
	$(MAKE) $(BUILDDIR)/$(EUBIND)
	$(MAKE) $(BUILDDIR)/$(EUSHROUD)

.PHONY : library debug-library
.PHONY : builddirs
.PHONY : interpreter
.PHONY : translator
.PHONY : svn_rev
.PHONY : code-page-db-rm $(BUILDDIR)/eui
.PHONY : binder

euisource : $(BUILDDIR)/intobj/main-.c
euisource :  EU_TARGET = int.ex
euisource : $(BUILDDIR)/include/be_ver.h
eucsource : $(BUILDDIR)/transobj/main-.c
eucsource :  EU_TARGET = ec.ex
eucsource : $(BUILDDIR)/include/be_ver.h
backendsource : $(BUILDDIR)/backobj/main-.c
backendsource :  EU_TARGET = backend.ex
backendsource : $(BUILDDIR)/include/be_ver.h

source : builddirs
	$(MAKE) euisource OBJDIR=intobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) eucsource OBJDIR=transobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
	$(MAKE) backendsource OBJDIR=backobj EBSD=$(EBSD) CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

ifneq "$(VERSION)" ""
SOURCEDIR=euphoria-$(VERSION)
else

ifeq "$(REV)" ""
REV := $(shell hg parents --template '{node|short}')
endif

ifeq "$(PLAT)" ""
SOURCEDIR=euphoria-$(REV)
else
SOURCEDIR=euphoria-$(PLAT)-$(REV)
endif

endif

source-tarball :
	rm -rf $(BUILDDIR)/$(SOURCEDIR)
	hg archive $(BUILDDIR)/$(SOURCEDIR)
	cd $(BUILDDIR)/$(SOURCEDIR)/source && ./configure $(CONFIGURE_PARAMS)
	$(MAKE) -C $(BUILDDIR)/$(SOURCEDIR)/source source
	rm $(BUILDDIR)/$(SOURCEDIR)/source/config.gnu
	rm $(BUILDDIR)/$(SOURCEDIR)/source/build/mkver$(EXE_EXT)
	cd $(BUILDDIR) && tar -zcf $(SOURCEDIR).tar.gz $(SOURCEDIR)
ifneq "$(VERSION)" ""
	cd $(BUILDDIR) && mkdir -p $(PLAT) && mv $(SOURCEDIR).tar.gz $(PLAT)
endif

.PHONY : euisource
.PHONY : eucsource
.PHONY : backendsource
.PHONY : source

ifeq "$(EMINGW)" "1"
$(EUI_RES) : eui.rc version_info.rc eu.manifest
$(EUIW_RES) : euiw.rc version_info.rc eu.manifest
endif

$(BUILDDIR)/$(EEXU) :  EU_TARGET = int.ex
$(BUILDDIR)/$(EEXU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_INTERPRETER_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EEXU) :  EU_OBJS = $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EEXU) :  $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) $(EU_TRANSLATOR_FILES) $(EUI_RES) $(EUIW_RES)
	@$(ECHO) making $(EEXU)
	@echo $(OS)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EUI_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXU)
	$(CC) $(EOSFLAGS) $(EUIW_RES) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EEXUW)
else
	$(CC) $(EOSFLAGS) $(EU_INTERPRETER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(PROFILE_FLAGS) $(MSIZE) -o $(BUILDDIR)/$(EEXU)
endif

$(BUILDDIR)/$(OBJDIR)/back/be_machine.o : $(BUILDDIR)/include/be_ver.h

ifeq "$(EMINGW)" "1"
$(EUC_RES) : euc.rc version_info.rc eu.manifest
endif

$(BUILDDIR)/$(EECU) :  OBJDIR = transobj
$(BUILDDIR)/$(EECU) :  EU_TARGET = ec.ex
$(BUILDDIR)/$(EECU) :  EU_MAIN = $(EU_CORE_FILES) $(EU_TRANSLATOR_FILES) $(EU_STD_INC)
$(BUILDDIR)/$(EECU) :  EU_OBJS = $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EECU) : $(EU_TRANSLATOR_OBJECTS) $(EU_BACKEND_OBJECTS) $(EUC_RES)
	@$(ECHO) making $(EECU)
	$(CC) $(EOSFLAGSCONSOLE) $(EUC_RES) $(EU_TRANSLATOR_OBJECTS) $(DEBUG_FLAGS) $(PROFILE_FLAGS) $(EU_BACKEND_OBJECTS) $(MSIZE) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EECU) 
	
backend : builddirs
ifeq "$(EUPHORIA)" "1"
	$(MAKE) backendsource EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG)  EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)
endif	
	$(MAKE) $(BUILDDIR)/$(EBACKENDU) EBACKEND=1 OBJDIR=backobj CONFIG=$(CONFIG) EDEBUG=$(EDEBUG) EPROFILE=$(EPROFILE)

ifeq "$(EMINGW)" "1"
$(EUB_RES) : eub.rc version_info.rc eu.manifest
$(EUBW_RES) : eubw.rc version_info.rc eu.manifest
endif

$(BUILDDIR)/$(EBACKENDU) : OBJDIR = backobj
$(BUILDDIR)/$(EBACKENDU) : EU_TARGET = backend.ex
$(BUILDDIR)/$(EBACKENDU) : EU_MAIN = $(EU_BACKEND_RUNNER_FILES)
$(BUILDDIR)/$(EBACKENDU) : EU_OBJS = $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS)
$(BUILDDIR)/$(EBACKENDU) : $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) $(EUB_RES) $(EUBW_RES)
	@$(ECHO) making $(EBACKENDU) $(OBJDIR)
	$(CC) $(EOSFLAGS) $(EUBW_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) $(DEBUG_FLAGS) $(MSIZE) $(PROFILE_FLAGS) -o $(BUILDDIR)/$(EBACKENDU)
ifeq "$(EMINGW)" "1"
	$(CC) $(EOSFLAGSCONSOLE) $(EUB_RES) $(EU_BACKEND_RUNNER_OBJECTS) $(EU_BACKEND_OBJECTS) -lm $(LDLFLAG) $(COVERAGELIB) -o $(BUILDDIR)/$(EBACKENDC)
endif

ifeq "$(HG)" ""
HG=hg
endif

.PHONY: update-version-cache
update-version-cache : $(MKVER)
	$(WINE) $(MKVER) "$(HG)" "$(BUILDDIR)/ver.cache" "$(BUILDDIR)/include/be_ver.h" $(EREL_TYPE)$(RELEASE)

$(MKVER): mkver.c
	$(CC) -o $@ $<


$(BUILDDIR)/ver.cache : update-version-cache

$(BUILDDIR)/include/be_ver.h:  $(BUILDDIR)/ver.cache
	

###############################################################################
#
# Documentation
#
###############################################################################

get-eudoc: $(TRUNKDIR)/source/eudoc/eudoc.ex
get-creole: $(TRUNKDIR)/source/creole/creole.ex

$(TRUNKDIR)/source/eudoc/eudoc.ex :
	hg clone http://scm.openeuphoria.org/hg/eudoc $(TRUNKDIR)/source/eudoc

$(TRUNKDIR)/source/creole/creole.ex :
	hg clone http://scm.openeuphoria.org/hg/creole $(TRUNKDIR)/source/creole

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

$(BUILDDIR)/html/js/scriptaculous.js: $(DOCDIR)/scriptaculous.js  $(BUILDDIR)/html/js
	copy $(DOCDIR)/scriptaculous.js $^@

$(BUILDDIR)/html/js/prototype.js: $(DOCDIR)/prototype.js  $(BUILDDIR)/html/js
	copy $(DOCDIR)/prototype.js $^@

htmldoc : $(BUILDDIR)/html/index.html
	echo $(EU_STD_INC)
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
test : 
test :  
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include ../source/eutest.ex -i ../include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind "$(CYPBUILDDIR)/$(EUBIND)" -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		$(TESTFILE)
	cd ../tests && sh check_diffs.sh

testeu : 
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) $(EXE) ../source/eutest.ex -i ../include -cc gcc -exe "$(CYPBUILDDIR)/$(EEXU) -batch $(CYPTRUNKDIR)/source/eu.ex" $(TESTFILE)

test-311 :
	cd ../tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include -cc gcc $(VERBOSE_TESTS) \
		-exe "$(CYPBUILDDIR)/$(EEXU)" \
		-ec "$(CYPBUILDDIR)/$(EECU)" \
		-eubind $(CYPBUILDDIR)/$(EUBIND) -eub $(CYPBUILDDIR)/$(EBACKENDC) \
		-lib "$(CYPBUILDDIR)/$(LIBRARY_NAME)" \
		$(TESTFILE)
		
coverage-311 :
	cd ../tests/311 && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test-311.edb -coverage $(CYPTRUNKDIR)/include \
		-coverage-exclude std -coverage-exclude euphoria \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

coverage : 
	cd ../tests && EUDIR=$(CYPTRUNKDIR) EUCOMPILEDIR=$(CYPTRUNKDIR) \
		$(EXE) -i ../include $(CYPTRUNKDIR)/source/eutest.ex -i $(CYPTRUNKDIR)/include \
		-exe "$(CYPBUILDDIR)/$(EEXU)" $(COVERAGE_ERASE) \
		-coverage-db $(CYPBUILDDIR)/unit-test.edb -coverage $(CYPTRUNKDIR)/include/std \
		 -coverage-pp "$(EXE) -i $(CYPTRUNKDIR)/include $(CYPTRUNKDIR)/bin/eucoverage.ex" $(TESTFILE)

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
	install $(BUILDDIR)/$(EECUSOA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EECUSODBGA) $(DESTDIR)$(PREFIX)/lib
	install $(BUILDDIR)/$(EEXU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EECU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EBACKENDU) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUBIND) $(DESTDIR)$(PREFIX)/bin
	install $(BUILDDIR)/$(EUSHROUD) $(DESTDIR)$(PREFIX)/bin
ifeq "$(EMINGW)" "1"
	install $(BUILDDIR)/$(EBACKENDC) $(DESTDIR)$(PREFIX)/bin
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

ifeq "$(EMINGW)" "1"
	MINGW_FLAGS=-gcc
else
	MINGW_FLAGS=
endif

ifeq "$(ARCH)" "ARM"
	EUC_CFLAGS=-cflags "-fomit-frame-pointer -c -w -fsigned-char -O2 -I$(TRUNKDIR) -ffast-math"
	EUC_LFLAGS=-lflags "$(BUILDDIR)/eu.a -ldl -lm -lpthread"
else
	EUC_CFLAGS=
	EUC_LFLAGS=
endif

$(BUILDDIR)/eudist-build/main-.c : eudist.ex
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eudist-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUDIST)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eudist.ex

$(BUILDDIR)/$(EUDIST) : $(TRUNKDIR)/source/eudist.ex translator library $(BUILDDIR)/eudist-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eudist-build" -f eudist.mak

$(BUILDDIR)/eudis-build/main-.c : $(TRUNKDIR)/source/dis.ex  $(TRUNKDIR)/source/dis.e $(TRUNKDIR)/source/dox.e
$(BUILDDIR)/eudis-build/main-.c : $(EU_CORE_FILES) 
$(BUILDDIR)/eudis-build/main-.c : $(EU_INTERPRETER_FILES) 
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eudis-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUDIS)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/dis.ex

$(BUILDDIR)/$(EUDIS) : translator library $(BUILDDIR)/eudis-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eudis-build" -f dis.mak

$(BUILDDIR)/bind-build/main-.c : $(TRUNKDIR)/source/bind.ex $(EU_INTERPRETER_FILES) $(EU_BACKEND_RUNNER_FILES)
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/bind-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUBIND)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/bind.ex

$(BUILDDIR)/$(EUBIND) : $(BUILDDIR)/bind-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/bind-build" -f bind.mak

$(BUILDDIR)/shroud-build/main-.c : $(TRUNKDIR)/source/shroud.ex  $(EU_INTERPRETER_FILES) $(EU_BACKEND_RUNNER_FILES)
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/shroud-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUSHROUD)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/shroud.ex

$(BUILDDIR)/$(EUSHROUD) : $(BUILDDIR)/shroud-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/shroud-build" -f shroud.mak

$(BUILDDIR)/eutest-build/main-.c : $(TRUNKDIR)/source/eutest.ex
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eutest-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUTEST)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/source/eutest.ex

$(BUILDDIR)/$(EUTEST) : $(BUILDDIR)/eutest-build/main-.c
		$(MAKE) -C "$(BUILDDIR)/eutest-build" -f eutest.mak

$(BUILDDIR)/eucoverage-build/main-.c : $(TRUNKDIR)/bin/eucoverage.ex
	$(BUILDDIR)/$(EECU) -build-dir "$(BUILDDIR)/eucoverage-build" \
		-i $(TRUNKDIR)/include \
		-o "$(BUILDDIR)/$(EUCOVERAGE)" \
		-lib "$(BUILDDIR)/eu.a" \
		-makefile -eudir $(TRUNKDIR) $(EUC_CFLAGS) $(EUC_LFLAGS) \
		$(MINGW_FLAGS) $(TRUNKDIR)/bin/eucoverage.ex

$(BUILDDIR)/$(EUCOVERAGE) : $(BUILDDIR)/eucoverage-build/main-.c
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
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html
	install  \
		$(BUILDDIR)/html/images/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/images
	install  \
		$(BUILDDIR)/html/js/* \
		$(DESTDIR)$(PREFIX)/share/doc/euphoria/html/js

# This doesn't seem right. What about eushroud ?
uninstall :
	-rm $(PREFIX)/bin/$(EEXU) $(PREFIX)/bin/$(EECU) $(PREFIX)/lib/$(EECUA) $(PREFIX)/lib/$(EECUDBGA) $(PREFIX)/bin/$(EBACKENDU)
ifeq "$(EMINGW)" "1"
	-rm $(PREFIX)/lib/$(EBACKENDC)
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

$(BUILDDIR)/%.res : %.rc
	$(RC) $< -O coff -o $@
	
$(BUILDDIR)/$(OBJDIR)/%.o : $(BUILDDIR)/$(OBJDIR)/%.c
	$(CC) $(EBSDFLAG) $(FE_FLAGS) $(BUILDDIR)/$(OBJDIR)/$*.c -I/usr/share/euphoria -o$(BUILDDIR)/$(OBJDIR)/$*.o


ifeq "$(EUPHORIA)" "1"

$(BUILDDIR)/$(OBJDIR)/%.c : $(EU_MAIN)
	@$(ECHO) Translating $(EU_TARGET) to create $(EU_MAIN)
	rm -f $(BUILDDIR)/$(OBJDIR)/{*.c,*.o}
	(cd $(BUILDDIR)/$(OBJDIR);$(TRANSLATE) -nobuild $(CYPINCDIR) -$(XLTTARGETCC) $(RELEASE_FLAG) $(TARGETPLAT)  \
		-c $(CYPTRUNKDIR)/source/eu.cfg $(CYPTRUNKDIR)/source/$(EU_TARGET) )
	
endif

ifneq "$(OBJDIR)" ""
$(BUILDDIR)/$(OBJDIR)/back/%.o : %.c $(CONFIG_FILE)
	$(CC) $(BE_FLAGS) $(EBSDFLAG) -I $(BUILDDIR)/$(OBJDIR)/back -I $(BUILDDIR)/include $*.c -o$(BUILDDIR)/$(OBJDIR)/back/$*.o

$(BUILDDIR)/$(OBJDIR)/back/be_callc.o : ./$(BE_CALLC).c $(CONFIG_FILE)
	$(CC) -c -Wall $(EOSTYPE) $(FPIC) $(EOSFLAGS) $(EBSDFLAG) $(MSIZE) -fsigned-char -O3 -fno-omit-frame-pointer -ffast-math -fno-defer-pop $(CALLC_DEBUG) $(BE_CALLC).c -o$(BUILDDIR)/$(OBJDIR)/back/be_callc.o

$(BUILDDIR)/$(OBJDIR)/back/be_inline.o : ./be_inline.c $(CONFIG_FILE) 
	$(CC) -finline-functions $(BE_FLAGS) $(EBSDFLAG) $(RUNTIME_FLAGS) be_inline.c -o$(BUILDDIR)/$(OBJDIR)/back/be_inline.o
endif
ifdef PCRE_OBJECTS	
$(PREFIXED_PCRE_OBJECTS) : $(patsubst %.o,pcre/%.c,$(PCRE_OBJECTS)) pcre/config.h.unix pcre/pcre.h.unix
	$(MAKE) -C pcre all CC="$(PCRE_CC)" PCRE_CC="$(PCRE_CC)" EOSTYPE="$(EOSTYPE)" EOSFLAGS="$(EOSPCREFLAGS)" CONFIG=../$(CONFIG) FPIC=$(FPIC)
endif

depend :
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/intobj/back/'
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/transobj/back/' -a
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/backobj/back/' -a
	makedepend -fMakefile.gnu -Y. -I. *.c -p'$$(BUILDDIR)/libobj/back/' -a

# The dependencies below are automatically generated using the depend target above.
# DO NOT DELETE

$(BUILDDIR)/intobj/back/be_alloc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_alloc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_alloc.o: be_alloc.h
$(BUILDDIR)/intobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/intobj/back/be_coverage.o: be_coverage.h be_machine.h global.h
$(BUILDDIR)/intobj/back/be_coverage.o: object.h symtab.h execute.h
$(BUILDDIR)/intobj/back/be_debug.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_debug.o: redef.h reswords.h be_alloc.h be_debug.h
$(BUILDDIR)/intobj/back/be_debug.o: be_execute.h be_machine.h be_rterror.h
$(BUILDDIR)/intobj/back/be_debug.o: be_runtime.h be_symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_decompress.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_decompress.o: be_runtime.h
$(BUILDDIR)/intobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/intobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/intobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/intobj/back/be_execute.o: be_callc.h be_coverage.h be_execute.h
$(BUILDDIR)/intobj/back/be_execute.o: be_debug.h be_memstruct.h
$(BUILDDIR)/intobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/intobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/intobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/intobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/intobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/intobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/intobj/back/be_machine.o: be_coverage.h be_syncolor.h be_debug.h
$(BUILDDIR)/intobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/intobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/intobj/back/be_main.o: be_w.h
$(BUILDDIR)/intobj/back/be_memstruct.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_memstruct.o: reswords.h redef.h be_alloc.h
$(BUILDDIR)/intobj/back/be_memstruct.o: be_machine.h be_memstruct.h
$(BUILDDIR)/intobj/back/be_memstruct.o: be_runtime.h
$(BUILDDIR)/intobj/back/be_pcre.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_pcre.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_pcre.o: be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/intobj/back/be_pcre.o: be_machine.h
$(BUILDDIR)/intobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/intobj/back/be_rterror.o: be_alloc.h be_syncolor.h be_debug.h
$(BUILDDIR)/intobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_rterror.h be_coverage.h be_execute.h
$(BUILDDIR)/intobj/back/be_runtime.o: be_symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/intobj/back/be_socket.o: be_machine.h be_runtime.h be_socket.h
$(BUILDDIR)/intobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/intobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/intobj/back/be_syncolor.o: be_w.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_syncolor.o: execute.h alldefs.h reswords.h
$(BUILDDIR)/intobj/back/be_syncolor.o: be_alloc.h be_machine.h be_syncolor.h
$(BUILDDIR)/intobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/intobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/intobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/intobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/intobj/back/be_w.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/intobj/back/be_w.o: execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/intobj/back/be_w.o: be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/intobj/back/rbt.o: rbt.h

$(BUILDDIR)/transobj/back/be_alloc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_alloc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_alloc.o: be_alloc.h
$(BUILDDIR)/transobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/transobj/back/be_coverage.o: be_coverage.h be_machine.h global.h
$(BUILDDIR)/transobj/back/be_coverage.o: object.h symtab.h execute.h
$(BUILDDIR)/transobj/back/be_debug.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_debug.o: redef.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_debug.o: be_debug.h be_execute.h be_machine.h
$(BUILDDIR)/transobj/back/be_debug.o: be_rterror.h be_runtime.h be_symtab.h
$(BUILDDIR)/transobj/back/be_decompress.o: alldefs.h global.h object.h
$(BUILDDIR)/transobj/back/be_decompress.o: symtab.h execute.h reswords.h
$(BUILDDIR)/transobj/back/be_decompress.o: be_alloc.h be_runtime.h
$(BUILDDIR)/transobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/transobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/transobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/transobj/back/be_execute.o: be_callc.h be_coverage.h be_execute.h
$(BUILDDIR)/transobj/back/be_execute.o: be_debug.h be_memstruct.h
$(BUILDDIR)/transobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/transobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/transobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/transobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/transobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/transobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/transobj/back/be_machine.o: be_coverage.h be_syncolor.h
$(BUILDDIR)/transobj/back/be_machine.o: be_debug.h
$(BUILDDIR)/transobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/transobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/transobj/back/be_main.o: be_w.h
$(BUILDDIR)/transobj/back/be_memstruct.o: execute.h global.h object.h
$(BUILDDIR)/transobj/back/be_memstruct.o: symtab.h reswords.h redef.h
$(BUILDDIR)/transobj/back/be_memstruct.o: be_alloc.h be_machine.h
$(BUILDDIR)/transobj/back/be_memstruct.o: be_memstruct.h be_runtime.h
$(BUILDDIR)/transobj/back/be_pcre.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_pcre.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_pcre.o: be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/transobj/back/be_pcre.o: be_machine.h
$(BUILDDIR)/transobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/transobj/back/be_rterror.o: be_alloc.h be_syncolor.h be_debug.h
$(BUILDDIR)/transobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_rterror.h be_coverage.h
$(BUILDDIR)/transobj/back/be_runtime.o: be_execute.h be_symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/transobj/back/be_socket.o: be_machine.h be_runtime.h be_socket.h
$(BUILDDIR)/transobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/transobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/transobj/back/be_syncolor.o: be_w.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_syncolor.o: execute.h alldefs.h reswords.h
$(BUILDDIR)/transobj/back/be_syncolor.o: be_alloc.h be_machine.h
$(BUILDDIR)/transobj/back/be_syncolor.o: be_syncolor.h
$(BUILDDIR)/transobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/transobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/transobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/transobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/transobj/back/be_w.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/transobj/back/be_w.o: execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/transobj/back/be_w.o: be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/transobj/back/rbt.o: rbt.h

$(BUILDDIR)/backobj/back/be_alloc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_alloc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_alloc.o: be_alloc.h
$(BUILDDIR)/backobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/backobj/back/be_coverage.o: be_coverage.h be_machine.h global.h
$(BUILDDIR)/backobj/back/be_coverage.o: object.h symtab.h execute.h
$(BUILDDIR)/backobj/back/be_debug.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_debug.o: redef.h reswords.h be_alloc.h be_debug.h
$(BUILDDIR)/backobj/back/be_debug.o: be_execute.h be_machine.h be_rterror.h
$(BUILDDIR)/backobj/back/be_debug.o: be_runtime.h be_symtab.h
$(BUILDDIR)/backobj/back/be_decompress.o: alldefs.h global.h object.h
$(BUILDDIR)/backobj/back/be_decompress.o: symtab.h execute.h reswords.h
$(BUILDDIR)/backobj/back/be_decompress.o: be_alloc.h be_runtime.h
$(BUILDDIR)/backobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/backobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/backobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/backobj/back/be_execute.o: be_callc.h be_coverage.h be_execute.h
$(BUILDDIR)/backobj/back/be_execute.o: be_debug.h be_memstruct.h
$(BUILDDIR)/backobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/backobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/backobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/backobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/backobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/backobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/backobj/back/be_machine.o: be_coverage.h be_syncolor.h be_debug.h
$(BUILDDIR)/backobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/backobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/backobj/back/be_main.o: be_w.h
$(BUILDDIR)/backobj/back/be_memstruct.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_memstruct.o: reswords.h redef.h be_alloc.h
$(BUILDDIR)/backobj/back/be_memstruct.o: be_machine.h be_memstruct.h
$(BUILDDIR)/backobj/back/be_memstruct.o: be_runtime.h
$(BUILDDIR)/backobj/back/be_pcre.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_pcre.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_pcre.o: be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/backobj/back/be_pcre.o: be_machine.h
$(BUILDDIR)/backobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/backobj/back/be_rterror.o: be_alloc.h be_syncolor.h be_debug.h
$(BUILDDIR)/backobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_rterror.h be_coverage.h
$(BUILDDIR)/backobj/back/be_runtime.o: be_execute.h be_symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/backobj/back/be_socket.o: be_machine.h be_runtime.h be_socket.h
$(BUILDDIR)/backobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/backobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/backobj/back/be_syncolor.o: be_w.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_syncolor.o: execute.h alldefs.h reswords.h
$(BUILDDIR)/backobj/back/be_syncolor.o: be_alloc.h be_machine.h be_syncolor.h
$(BUILDDIR)/backobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/backobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/backobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/backobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/backobj/back/be_w.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/backobj/back/be_w.o: execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/backobj/back/be_w.o: be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/backobj/back/rbt.o: rbt.h

$(BUILDDIR)/libobj/back/be_alloc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_alloc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_alloc.o: be_alloc.h
$(BUILDDIR)/libobj/back/be_callc.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_callc.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_callc.o: be_machine.h be_alloc.h
$(BUILDDIR)/libobj/back/be_coverage.o: be_coverage.h be_machine.h global.h
$(BUILDDIR)/libobj/back/be_coverage.o: object.h symtab.h execute.h
$(BUILDDIR)/libobj/back/be_debug.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_debug.o: redef.h reswords.h be_alloc.h be_debug.h
$(BUILDDIR)/libobj/back/be_debug.o: be_execute.h be_machine.h be_rterror.h
$(BUILDDIR)/libobj/back/be_debug.o: be_runtime.h be_symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_decompress.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_decompress.o: be_runtime.h
$(BUILDDIR)/libobj/back/be_execute.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_execute.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_execute.o: be_runtime.h be_decompress.h
$(BUILDDIR)/libobj/back/be_execute.o: be_inline.h be_machine.h be_task.h
$(BUILDDIR)/libobj/back/be_execute.o: be_rterror.h be_symtab.h be_w.h
$(BUILDDIR)/libobj/back/be_execute.o: be_callc.h be_coverage.h be_execute.h
$(BUILDDIR)/libobj/back/be_execute.o: be_debug.h be_memstruct.h
$(BUILDDIR)/libobj/back/be_inline.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_inline.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_machine.o: global.h object.h symtab.h alldefs.h
$(BUILDDIR)/libobj/back/be_machine.o: execute.h reswords.h version.h
$(BUILDDIR)/libobj/back/be_machine.o: be_runtime.h be_rterror.h be_main.h
$(BUILDDIR)/libobj/back/be_machine.o: be_w.h be_symtab.h be_machine.h
$(BUILDDIR)/libobj/back/be_machine.o: be_pcre.h pcre/pcre.h be_task.h
$(BUILDDIR)/libobj/back/be_machine.o: be_alloc.h be_execute.h be_socket.h
$(BUILDDIR)/libobj/back/be_machine.o: be_coverage.h be_syncolor.h be_debug.h
$(BUILDDIR)/libobj/back/be_main.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_main.o: execute.h reswords.h be_runtime.h
$(BUILDDIR)/libobj/back/be_main.o: be_execute.h be_alloc.h be_rterror.h
$(BUILDDIR)/libobj/back/be_main.o: be_w.h
$(BUILDDIR)/libobj/back/be_memstruct.o: execute.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_memstruct.o: reswords.h redef.h be_alloc.h
$(BUILDDIR)/libobj/back/be_memstruct.o: be_machine.h be_memstruct.h
$(BUILDDIR)/libobj/back/be_memstruct.o: be_runtime.h
$(BUILDDIR)/libobj/back/be_pcre.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_pcre.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_pcre.o: be_runtime.h be_pcre.h pcre/pcre.h
$(BUILDDIR)/libobj/back/be_pcre.o: be_machine.h
$(BUILDDIR)/libobj/back/be_rterror.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: execute.h reswords.h be_rterror.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_runtime.h be_task.h be_w.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_machine.h be_execute.h be_symtab.h
$(BUILDDIR)/libobj/back/be_rterror.o: be_alloc.h be_syncolor.h be_debug.h
$(BUILDDIR)/libobj/back/be_runtime.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_runtime.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_runtime.h be_machine.h be_inline.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_w.h be_callc.h be_task.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_rterror.h be_coverage.h be_execute.h
$(BUILDDIR)/libobj/back/be_runtime.o: be_symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_socket.o: execute.h reswords.h be_alloc.h
$(BUILDDIR)/libobj/back/be_socket.o: be_machine.h be_runtime.h be_socket.h
$(BUILDDIR)/libobj/back/be_symtab.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_symtab.o: execute.h reswords.h be_execute.h
$(BUILDDIR)/libobj/back/be_symtab.o: be_alloc.h be_machine.h be_runtime.h
$(BUILDDIR)/libobj/back/be_syncolor.o: be_w.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_syncolor.o: execute.h alldefs.h reswords.h
$(BUILDDIR)/libobj/back/be_syncolor.o: be_alloc.h be_machine.h be_syncolor.h
$(BUILDDIR)/libobj/back/be_task.o: global.h object.h symtab.h execute.h
$(BUILDDIR)/libobj/back/be_task.o: reswords.h be_runtime.h be_task.h
$(BUILDDIR)/libobj/back/be_task.o: be_alloc.h be_machine.h be_execute.h
$(BUILDDIR)/libobj/back/be_task.o: be_symtab.h alldefs.h
$(BUILDDIR)/libobj/back/be_w.o: alldefs.h global.h object.h symtab.h
$(BUILDDIR)/libobj/back/be_w.o: execute.h reswords.h be_w.h be_machine.h
$(BUILDDIR)/libobj/back/be_w.o: be_runtime.h be_rterror.h be_alloc.h
$(BUILDDIR)/libobj/back/rbt.o: rbt.h
