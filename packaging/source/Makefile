include Makefile.eu

ROOTDIR := $(shell pwd)

all : linux windows osx freebsd openbsd netbsd

linux : 
	$(MAKE) source-tarball PLATFORM=LINUX

windows :
	$(MAKE) source-tarball PLATFORM=WINDOWS

osx :
	$(MAKE) source-tarball PLATFORM=OSX

freebsd :
	$(MAKE) source-tarball PLATFORM=FREEBSD

openbsd :
	$(MAKE) source-tarball PLATFORM=OPENBSD

netbsd :
	$(MAKE) source-tarball PLATFORM=NETBSD

clean :
	-rm -r build

source-tarball : 
	echo Making source-tarball for $(PLATFORM)
	cd ../../source/ && ./configure $(CONFIG) --plat $(PLATFORM) --build $(ROOTDIR)/build
	make -C ../../source clean
	make -C ../../source source-tarball -j2 VERSION=$(VERSION)

.PHONY : linux windows osx freebsd openbsd netbsds all clean
