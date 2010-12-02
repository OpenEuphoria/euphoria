#!/usr/bin/env bash

#
# Ensure a directory name was given as a command line option
#

if [ "$1" = "" ] || [ "$2" = "" ]; then
	echo Usage: build.sh PLATFORM TAG-NAME
        exit
fi

PLATFORM=$1
TAG=$2
REL_NAME=euphoria-${TAG}-${PLATFORM}

svn export https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/tags/${TAG} ${REL_NAME}

cd ${REL_NAME}/bin
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

tar czf ${REL_NAME}.tar.gz ${REL_NAME}

