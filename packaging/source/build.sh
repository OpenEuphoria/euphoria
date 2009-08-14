#!/bin/sh

#
# Ensure a tag name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh TAG-NAME
        exit
fi

rm -f euphoria-$1.tar.gz
svn export https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/tags/$1 euphoria-src-$1

cd euphoria-$1/bin
rm -f *.bat *.ico make31.exw *.exe
chmod ug+rwx,o+rx Linux/*
cp Linux/* .
rm -rf Linux FreeBSD
cd ../

tar czf euphoria-src-$1.tar.gz euphoria-src-$1
