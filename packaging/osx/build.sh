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
REL_NAME=euphoria-OSX-${VERSION}${OPT}
ROOTDIR=../../..

echo Cleaning previous working directory
rm -rf ${REL_NAME}

echo Getting a clean Mercurial archive
hg archive $REL_NAME

echo Removing unnecessary file for *nix installs
cd ${REL_NAME}/bin
rm -f *.bat *.ico make31.exw *.exe
cd ..

rm -rf docs
rm -rf packaging

echo Copying other misc files to bin/
cp ${ROOTDIR}/bin/ecp.dat ${ROOTDIR}/bin/eu{.a,dbg.a} bin

echo Copying docs to our distribution directory
mkdir docs
cp ${ROOTDIR}/source/build/*.pdf docs

BINS=`ls ${ROOTDIR}/bin/eu{b,bind,c,i,shroud} ${ROOTDIR}/bin/eu{coverage,dis,dist,doc,loc,test} ${ROOTDIR}/bin/creole`
for f in ${BINS}; do
	echo Stripping/copying ${f}
	strip ${f}
	cp ${f} bin
done

cd ..

echo Setting ownership
sudo chown -R root:wheel ${REL_NAME}

echo Creating distribution tar.gz
tar czf ${REL_NAME}.tar.gz ${REL_NAME}

echo Creating distribution tar.bz2
tar cjf ${REL_NAME}.tar.bz2 ${REL_NAME}

echo Done!
