# This script determines if the following are true:
#       All routines or variables found in std/memory.e are also be complimented with a  version for std/safe.e with the same name. 
#	The sets of symbols exported by std/safe.e and std/memory.e are the same. 
#
# The user should use std/machine.e for his/her programs.  If SAFE is defined std/safe.e   
# will implement SAFE behavior for std/machine.e if not memory.e will implement faster behavior
# for std/machine.e.
#
egrep 'export ' ../include/std/safe.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;}' > exported_from_safe.txt 
egrep 'export ' ../include/std/memory.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;}' > exported_from_memory.txt
if diff exported_from_safe.txt exported_from_memory.txt; then
	echo "Both std/memory.e and std/safe.e provide the same interface to std/machine.e....good." 
else
	echo "Error: std/memory.e and std/safe.e export different symbols to std/machine.e....bad."
	exit 1
fi
egrep 'public ' ../include/std/safe.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;}' > publicized_from_safe.txt 
egrep 'public ' ../include/std/memory.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;}' > publicized_from_memory.txt
if diff publicized_from_safe.txt publicized_from_memory.txt | grep '>'; then
	echo "Error: std/memory.e symbols not in std/safe.e to all files        ...bad."
	exit 1
else
	echo "The include std/safe.e provides as many symbols as as std/memory.e...good." 
fi
