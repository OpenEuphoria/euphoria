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

# Fail now from problems that would otherwise need to fail later in the script
if [ ! -e include/euphoria.h ]; then
	# Not in base directory, maybe we are deep inside of it?
	cd ../..
fi
if [ ! -e packaging/slackware ]; then
	echo "Please run from base directory"
	exit;
fi
if [ ! -e ../eudoc/build/eudoc ]; then
	echo "Must have a eudoc directory below the source distro with compiled eudoc."
	exit
fi
if [ ! -e ../creole/build/creole ]; then
	echo "Must have a creole directory below the source distro with compiled creole."
	exit
fi
rm -fr packaging/slackware/inst
if [ -e packaging/slackware/inst ] ; then
	echo "please remove packaging/slackware/inst as root and run again. "
    exit
fi


# Carefully clean most of the files
# hg sta -uai | grep -v inst | grep -v linux-build | grep -v slackware | awk '{ print $2; }' | xargs rm -fv || /bin/true
FILES=`hg sta -muai`

( cd source ; sh configure --release 1 --build ../linux-build; make source )    
    	    	 
make -C source htmldoc pdfdoc
if [ ! -e linux-build/eub ]; then
    tar cf linux-source-${ARCH}.tar.xz linux-build
fi

make -C source all
tar cf linux-build-${ARCH}.tar.xz linux-build
# building produces but one file in the otherwise pristine sub-trees of include, bin, demo, bin, etc...
# in some versions it doesn't exist.
rm -f source/eu.cfg
cd ..
# by here there should be C source code in ./linux-build and
# only C source code in linux-build.tar.gz

set -e

( cd source; make library all )
cd packaging/slackware
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
    echo "OR become root now and type:"
    echo "   cd packaging/slackware/inst"
    echo "   chown root.root -R ."
    echo "   /sbin/makepkg -c y -l y ../euphoria-${VERSION}-${ARCH}-${PVER}.tgz"
fi

if [ "x"$FILES != "x" ]; then
    	echo "Warning: There were these files left laying around."
	/bin/false
fi


