#!/bin/bash
#
# Create Installation Directory inst, which will look like all of the files that need to be installed with their full paths.
# makepkg will put this into an archive.  One should run this as root, so the package files are owned by root on each machine
# installed.
#
# ## It must be run from a clean checkout.  Except it can have an archive named linux-build.tar.gz containing the translated
#    directories:  
#
# the user can run this from the checkout directory or from this directory
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

cd packaging/slackware
if [ -e clean_branch ] ; then
	hg summary | grep parent  | awk '{ print $2; } ' | awk --field-separator=: '{ print $2;} '  | xargs  hg -R clean_branch update -r
else
	hg summary | grep parent  | awk '{ print $2; } ' | awk --field-separator=: '{ print $2;} '  | xargs hg clone ../.. clean_branch -u
fi
cd ../..

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
	rm source/eu.cfg
	cd ..
fi

set INST=packaging/slackware/inst
cd packaging/slackware
rm -fr inst
if [ -e inst ] ; then
	echo "please remove inst as root and run again. "
        exit
fi
mkdir -p inst/usr
make DESTDIR=`pwd`/inst PREFIX=/usr  -C ../../source install install-docs install-tools
mkdir -p inst/etc/euphoria inst/install
cp slackware-eu.cfg inst/etc/euphoria/eu.cfg
cp slack-desc inst/install

if [ ! -e inst ] ; then
	echo "problem! inst not found. "
	exit
fi
echo "become root, "
echo "cd to inst and type "
makepkg -c y euphoria-4.1.0al-i486-1.tgz inst

