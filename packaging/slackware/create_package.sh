#!/bin/bash
#
# Create a Package appropriate for Slackware
# makepkg will put this into an archive.  One should run this as root, so the package files are owned by root on each machine
# installed.
#
# ## It must be run from a clean checkout.  Except it can have an archive named linux-build.tar.gz containing the translated
#    directories:  
#
# the user can run this from the checkout directory or from this directory
# The script must use root access to create a package with root user owned packages.

VERSION=4.1.0al
ARCH=i486
PVER=1
set -e

if [ ! -e include/euphoria.h ]; then
	# Not in base directory, maybe we are deep inside of it?
	cd ../..
fi
if [ ! -e packaging/slackware ]; then
	echo "Please run from base directory"
	exit;
fi

# Carefully clean most of the files
# hg sta -umai | grep -v inst | grep -v linux-build | grep -v slackware | awk '{ print $2; }' | xargs rm -v

if [ ! -e linux-build ]; then
	if [ -e linux-build.tar.gz ]; then
#		translating the sources alone creates exe files on Windows, make sure we don't keep them here.
		tar -xzf linux-build.tar.gz &&
		rm -f linux-build/*.exe
		cd source
		sh configure --build ../linux-build --without-euphoria
	else
		cd source
		sh configure --build ../linux-build
	fi
	make all htmldoc pdfdoc
	# building produces but one file in the otherwise pristine sub-trees of include, bin, demo, bin, etc...
	# in some versions it doesn't exist.
	rm -f source/eu.cfg
	cd ..
else
        # for make install
	( cd source; sh configure --build ../linux-build )    
fi

cd packaging/slackware
rm -fr inst
if [ -e inst ] ; then
	echo "please remove inst as root and run again. "
        exit
fi
mkdir -p inst/usr/bin
mkdir -p inst/etc/euphoria inst/install inst/usr/doc
cp -v ../../../eudoc/build/eudoc inst/usr/bin || ( echo "Must have a eudoc directory below the source distro with compiled eudoc." && /bin/false )
cp -v ../../../creole/build/creole inst/usr/bin || ( echo "Must have a creole directory below the source distro with compiled creole." && /bin/false )
( make DESTDIR=`pwd`/inst PREFIX=/usr  -C ../../source install install-docs install-tools )
cd inst
cp -v ../../../demo/win32/* usr/share/euphoria/demo/win32
mkdir -p usr/share/euphoria/lib
mv ./usr/lib/* ./usr/share/euphoria/lib
mv ./usr/share/euphoria ./usr/share/euphoria-${VERSION}
mv ./usr/share/doc/euphoria ./usr/share/doc/euphoria-${VERSION}
mv ./usr/bin/* ./usr/share/euphoria-${VERSION}/bin/
( cd usr/share; ln -s euphoria-${VERSION} euphoria )
( cd usr/share/euphoria-${VERSION}/bin;
 for f in *; \
      do       
      	  strip $f 2> /dev/null || /bin/true	  
      ln -sf /usr/share/euphoria/bin/$f ../../../bin/$f;
      ln -sf /usr/share/euphoria-${VERSION}/bin/$f ../../../bin/$f-${VERSION};
done ;
)
( cd usr/share/euphoria-${VERSION}/lib;for f in *; \
      do ln -s /usr/share/euphoria/lib/$f ../../../lib/$f;
      ln -sf /usr/share/euphoria-${VERSION}/lib/$f ../../../lib/$f-${VERSION};
done )
echo "[all]\n-i /usr/share/euphoria-${VERSION}/include" > ./usr/share/euphoria-${VERSION}/bin/eu.cfg
cd ..
cp slack-desc inst/install
cd inst
find . \
 \( -xtype l -prune \) -o \
 \( -name bin -exec chmod -R 755 {} \; -prune \) -o \
 \( -type d -exec chmod 755 {} \; \) -o \
 \( -type f -exec chmod 644 {} \; \)
if [ `id -u` = '0' ]; then
    # You're root
    /sbin/makepkg -c y -l y ../euphoria-${VERSION}-${ARCH}-${PVER}.tgz
    cd ..; rm -r inst
else
    echo "You'll need to do this again, as root. So files will be owned as root."
    echo "Inspect inst to see where files will go."
fi
