#!/bin/sh

#
# Ensure a tag name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh TAG-NAME
        exit
fi

svn export https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/tags/$1 euphoria-$1

cd euphoria-$1/bin
rm -f *.bat *.ico make31.exw *.exe
chmod ug+rwx,o+rx Linux/*
cp Linux/* .
rm -rf Linux FreeBSD
cd ../
rm -rf docs packaging Setup

cp ../../../bin/eui ../../../bin/euc ../../../bin/eu.a ../../../bin/eudbg.a ../../../bin/eub bin

cd ..

tar czf euphoria-$1.tar.gz euphoria-$1
