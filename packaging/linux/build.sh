#!/bin/sh

#
# Ensure a tag name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh TAG-NAME
        exit
fi

rm -f euphoria-4.0a3.tar.gz
rm -rf cleanbranch
svn co https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/$1 cleanbranch

cd cleanbranch/bin
rm -f *.bat *.ico make31.exw *.exe
chmod ug+rwx,o+rx Linux/*
cp Linux/* .
rm -rf Linux FreeBSD
cd ../
rm -rf docs packaging Setup

cp ../../../bin/exu ../../../bin/ecu ../../../bin/ecu.a ../../../bin/backendu bin

cd ..

find cleanbranch -name .svn -exec rm -rf {} \;

mv cleanbranch euphoria-4.0a3

tar czf euphoria-4.0a3.tar.gz euphoria-4.0a3
