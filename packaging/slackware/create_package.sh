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


if [ ! -e packaging/slackware/inst ]; then
	mkdir -p packaging/slackware/inst/usr/{bin,include,doc,share/euphoria} &&
	cp -r include/* packaging/slackware/inst/usr/include &&
	cp -r bin/* packaging/slackware/inst/usr/bin &&
	cp -r linux-build/{pdf/euphoria.pdf,html} packaging/slackware/inst/usr/doc &&
	cp -r source demo tests tutorial packaging/slackware/inst/usr/share/euphoria &&
	find linux-build -perm u=rwx,g=rx,o=rx -type f -exec strip '{}' ';' -a -exec cp '{}' packaging/slackware/inst/usr/bin ';' ;
	cp packaging/slackware/slackware-eu.cfg packaging/slackware/inst/usr/bin/eu.cfg
fi

cd packaging/slackware
if [ ! -e euphoria-4.0.6-1.tgz ] ; then
	cd inst &&
	makepkg ../euphoria-4.0.6-1.tgz 
fi
