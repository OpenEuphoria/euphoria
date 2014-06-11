include Makefile.eu


all : linux windows osx freebsd openbsd netbsd

linux : 
	$(MAKE) source-tarball PLATFORM=LINUX ARCH=x86
	$(MAKE) source-tarball PLATFORM=LINUX ARCH=x86_64

windows :
	$(MAKE) source-tarball PLATFORM=WINDOWS ARCH=x86
	$(MAKE) source-tarball PLATFORM=WINDOWS ARCH=x86_64

osx :
	$(MAKE) source-tarball PLATFORM=OSX ARCH=x86
	$(MAKE) source-tarball PLATFORM=OSX ARCH=x86_64

freebsd :
	$(MAKE) source-tarball PLATFORM=FREEBSD ARCH=x86
	$(MAKE) source-tarball PLATFORM=FREEBSD ARCH=x86_64

openbsd :
	$(MAKE) source-tarball PLATFORM=OPENBSD ARCH=x86
	$(MAKE) source-tarball PLATFORM=OPENBSD ARCH=x86_64

netbsd :
	$(MAKE) source-tarball PLATFORM=NETBSD ARCH=x86
	$(MAKE) source-tarball PLATFORM=NETBSD ARCH=x86_64

clean :
	-rm -r LINUX-x86
	-rm -r WINDOWS
	-rm -r OSX
	-rm -r FREEBSD
	-rm -r OPENBSD
	-rm -r NETBSD
	-rm -r LINUX-x86_64
	-rm -r WINDOWS-x86_64
	-rm -r OSX-x86_64
	-rm -r FREEBSD-x86_64
	-rm -r OPENBSD-x86_64
	-rm -r NETBSD-x86_64

$(PLATFORM)-$(ARCH) :
	mkdir $(PLATFORM)-$(ARCH)

source-tarball : $(PLATFORM)-$(ARCH)
	echo Making source-tarball for $(PLATFORM)-$(ARCH)
	cd $(PLATFORM)-$(ARCH) && ../../../source/configure $(CONFIG) --plat $(PLATFORM) --arch $(ARCH)
	make -C $(PLATFORM)-$(ARCH) clean
	make -C $(PLATFORM)-$(ARCH) source-tarball -j2 VERSION=$(VERSION)

.PHONY : linux windows osx freebsd openbsd netbsds all clean
