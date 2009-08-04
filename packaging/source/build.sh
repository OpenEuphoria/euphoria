#!/bin/sh

#
# Ensure a tag name was given as a command line option
#

if [ "$1" = "" ]; then
	echo Usage: build.sh TAG-NAME
        exit
fi

rm -f euphoria-$1.tar.gz
rm -rf cleanbranch
svn co https://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria/$1 cleanbranch

find cleanbranch -name .svn -exec rm -rf {} \;

mv cleanbranch euphoria-src-$1

tar czf euphoria-src-$1.tar.gz euphoria-src-$1
