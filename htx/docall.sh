#!/bin/sh

echo creating DOCUMENTATION FILES
echo EUDIR is ${EUDIR}

# need syncolor.e and keywords.e - EUINC will be changed temporarily

export TEMP_EUINC=${EUINC}
export EUINC=${EUDIR}/bin

exu doc.exw HTML ${EUDIR}

# these files are only needed to update RDS Web site
rm -f ${EUDIR}/htx/refman_?.doc
rm -f ${EUDIR}/htx/lib_*.doc

export EUINC=${TEMP_EUINC}
