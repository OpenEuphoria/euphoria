#!/usr/bin/env bash

# update dependencies
makedepend -fMakefile.gnu -Y. -I. *.c -p'$(BUILDDIR)/intobj/back/' -a
makedepend -fMakefile.gnu -Y. -I. *.c -p'$(BUILDDIR)/transobj/back/' -a
makedepend -fMakefile.gnu -Y. -I. *.c -p'$(BUILDDIR)/backobj/back/' -a
makedepend -fMakefile.gnu -Y. -I. *.c -p'$(BUILDDIR)/libobj/back/' -a

# the sed call fails when invoked from within a Makefile
# we want to replace the actual directory with $(TRUNKDIR) so that everything will
# work as expected
sed -iold -re 's| ([^\.\$]\S+\.h\b)| $(TRUNKDIR)/source/\1|g' Makefile.gnu