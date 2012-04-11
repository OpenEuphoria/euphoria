include Makefile.eu

ROOTDIR := $(shell pwd)

all : linux windows osx freebsd openbsd netbsd

linux : PLATFORM=LINUX
linux : source-tarball

windows : PLATFORM=WINDOWSasdss
windows : source-tarball

osx : PLATFORM=OSX
osx : source-tarball

freebsd : PLATFORM=FREEBSD
freebsd : source-tarball

openbsd : PLATFORM=OPENBSD
openbsd : source-tarball

netbsd : PLATFORM=NETBSD
netbsd : source-tarball

clean :
	-rm -r build

source-tarball :
	echo Making source-tarball for $(PLATFORM)
	cd ../../source/ && ./configure $(CONFIG) --plat $(PLATFORM) --build $(ROOTDIR)/build
# 	make -C ../../source clean
# 	make -C ../../source source-tarball -j2 VERSION=$(VERSION)

.PHONY : linux windows osx freebsd openbsd netbsd source-tarball all clean
