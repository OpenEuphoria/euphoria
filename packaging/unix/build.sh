#!/usr/bin/env bash

#
# Ensure a directory name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh VERSION
	exit
fi

VERSION=$1
OPT=$2
REL_NAME=euphoria-${VERSION}${OPT}
ROOTDIR=../../..

# exit on error
set -e

echo Cleaning previous working directory
rm -rf ${REL_NAME}

echo Getting a clean SVN export
hg archive $REL_NAME

echo Removing unnecessary file for *nix installs
cd ${REL_NAME}/bin
rm -f *.bat *.ico make31.exw *.exe
cd ..

rm -rf docs
rm -rf packaging

BINS=`ls ${ROOTDIR}/source/build/eu{b,bind,c,i,shroud} ${ROOTDIR}/source/build/eu{coverage,dis,dist,test,loc} ${ROOTDIR}/../creole/build/creole ${ROOTDIR}/../eudoc/build/eudoc`
for f in ${BINS}; do
	echo Stripping/copying ${f}
	strip ${f}
	cp ${f} bin
done

echo Copying other misc files to bin/
cp ${ROOTDIR}/bin/ecp.dat ${ROOTDIR}/source/build/eu{.a,dbg.a} bin

echo Copying docs to our distribution directory

mkdir docs
cp -r ${ROOTDIR}/source/build/*.pdf ${ROOTDIR}/source/build/html docs

cd ..

echo Creating distribution tar.gz
tar czf ${REL_NAME}.tar.gz ${REL_NAME}

echo Creating distribution tar.bz2
tar cjf ${REL_NAME}.tar.bz2 ${REL_NAME}

echo Done!
