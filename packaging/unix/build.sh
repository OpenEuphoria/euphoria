#!/usr/bin/env bash

#
# Ensure a directory name was given as a command line option
#

if [ "$1" = "" ] || [ "$2" = "" ]; then
	echo Usage: build.sh SVN_PATH VERSION
        exit
fi

SVN_PATH=$1
VERSION=$2
OPT=$3
REL_NAME=euphoria-${VERSION}${OPT}
ROOTDIR=../../..

echo Cleaning previous working directory
rm -rf ${REL_NAME}

echo Getting a clean SVN export
svn export https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/${SVN_PATH} ${REL_NAME}

echo Removing unnecessary file for *nix installs
cd ${REL_NAME}/bin
rm -f *.bat *.ico make31.exw *.exe
cd ..

rm -rf docs
rm -rf packaging

echo Stripping binaries that will be installed
BINS=`ls ${ROOTDIR}/bin/eu{b,bind,c,i,shroud} ${ROOTDIR}/bin/eu{coverage,dis,dist,doc,loc,test} ${ROOTDIR}/bin/creolehtml`
for f in ${BINS}; do
	echo Stripping/copying ${f}
	strip ${f}
	cp ${f} bin
done

echo Copying compiled executables to our distribution directory
cp ${ROOTDIR}/bin/ecp.dat ${ROOTDIR}/bin/eu{.a,dbg.a} bin

echo Copying docs to our distribution directory

mkdir docs
cp ${ROOTDIR}/build/*.pdf docs

cd ..

echo Creating distribution tar.gz
tar czf ${REL_NAME}.tar.gz ${REL_NAME}

echo Creating distribution tar.bz2
tar cjf ${REL_NAME}.tar.bz2 ${REL_NAME}

echo Done!
