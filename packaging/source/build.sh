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

find cleanbranch -name .svn -exec rm -rf {} \;

mv cleanbranch euphoria-src-4.0a3

tar czf euphoria-src-4.0a3.tar.gz euphoria-src-4.0a3
zip -r euphoria-src-4.0a3.zip euphoria-src-4.0a3
