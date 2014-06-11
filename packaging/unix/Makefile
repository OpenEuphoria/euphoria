# Build a tarball distribution
# Uses existing configuration.
#
# Usage:
#       All binaries and docs must be built from the source directory first.
#       $ make DIR=path/to/build/dir VERSION=$version


ifeq "$(DIR)" ""
DIR=../../source
endif

include $(DIR)/config.gnu

ifeq "$(ELINUX)" "1"
OS=Linux
else ifeq "$(EOSX)" "1"
OS=OSX
else ifeq "$(EOPENBSD)" "1"
OS=OpenBSD
else ifeq "$(ENETBSD)" "1"
OS=NetBSD
else ifeq "$(EBSD)" "1"
OS=BSD
else ifeq "$(EMINGW)" "1"
OS=Windows
endif

REL_NAME=euphoria-${VERSION}${OPT}

REL_NAME=euphoria-$(VERSION)-$(OS)-$(ARCH)

BINS= \
	eui \
	eub \
	euc \
	eubind \
	eushroud \
	eucoverage \
	eudis \
	eudist \
	eutest

ifeq "$(ARCH)" "ix86_64"
EECUSOA=euso.a
EECUSODBGA=eusodbg.a
endif

LIBS= \
	eu.a \
	eudbg.a \
	euso.a \
	eusodbg.a

all :
	-rm -r $(REL_NAME)
	hg archive $(REL_NAME)
	-rm $(REL_NAME)/.hg*
	-rm -rf $(REL_NAME)/docs/* $(REL_NAME)/packaging
	-rm $(REL_NAME)/bin/*.bat $(REL_NAME)/bin/*.ico $(REL_NAME)/bin/make31.exw $(REL_NAME)/bin/*.exe
	for f in $(BINS) ; do \
		cp $(BUILDDIR)/$${f} $(REL_NAME)/bin ; \
# 		strip $(REL_NAME)/bin/$${f} ; \
	done ;
	for f in $(LIBS) ; do \
		cp $(BUILDDIR)/$${f} $(REL_NAME)/bin ; \
	done ;
	
	-cp $(BUILDDIR)/*.pdf $(REL_NAME)/docs
	-cp -r $(BUILDDIR)/html $(REL_NAME)/docs
	tar czf ${REL_NAME}.tar.gz ${REL_NAME}
	tar cjf ${REL_NAME}.tar.bz2 ${REL_NAME}

