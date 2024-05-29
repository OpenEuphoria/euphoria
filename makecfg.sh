#!/bin/bash
EUDIR=$(realpath $(dirname $0))
CONFIG=$EUDIR/bin/eu.cfg

#defarch
if [ "$(uname -m)" == "i686" ]; then DEFARCH="X86"; fi
if [ "$(uname -m)" == "x86_64" ]; then DEFARCH="X86_64"; fi

#setarch32
if [ "$1" == "X86" ]; then
  ARCH=$1
#setarch64
elif [ "$1" == "X86_64" ]; then
  ARCH=$1
#default
elif [ "$1" == "" ]; then
  ARCH=$DEFARCH
#badarch
else
  echo Invalid arch "$1"
  exit 1
fi

#makecfg
mkdir -p $EUDIR/bin
echo Writing contents to: $CONFIG
echo [all] > $CONFIG
echo -eudir $EUDIR >> $CONFIG
echo -i $EUDIR/include >> $CONFIG
echo [translate] >> $CONFIG
echo -arch $ARCH >> $CONFIG
echo -gcc >> $CONFIG
echo -com $EUDIR >> $CONFIG
echo -con >> $CONFIG
echo -lib-pic $EUDIR/bin/euso.a >> $CONFIG
echo -lib $EUDIR/bin/eu.a >> $CONFIG
echo [bind] >> $CONFIG
echo -eub $EUDIR/bin/eub >> $CONFIG
cat $CONFIG
read -p "Press any key to continue . . ."
