#!/bin/bash

#
# Ensure a directory name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh DIR-NAME
        exit
fi

svn export https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/$1 euphoria-$1

cd euphoria-$1/bin
rm -f *.bat *.ico make31.exw *.exe
cd ..

rm -rf docs
rm -rf packaging

cp ../../../bin/eu{i,b,c,doc,test,coverage,bind} ../../../bin/eu.a ../../../bin/eudbg.a bin
cp ../../../bin/creolehtml ../../../bin/ecp.dat bin

mkdir docs
cp ../../../build/*.pdf docs
cp -r ../../../build/html docs

cd ..

tar czf euphoria-$1.tar.gz euphoria-$1

