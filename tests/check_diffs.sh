egrep 'export ' ../include/std/safe.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;
}' > exported_from_safe.txt 
egrep 'export ' ../include/std/memory.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;
}' > exported_from_memory.txt
if diff exported_from_safe.txt exported_from_memory.txt; then
	echo "Both std/memory.e and std/safe.e provide the same interface to std/machine.e....good." 
else
	echo "Error: std/memory.e and std/safe.e export different symbols to std/machine.e....bad."
	exit 1
fi
egrep 'public ' ../include/std/safe.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;
}' > publicized_from_safe.txt 
egrep 'public ' ../include/std/memory.e | sort | awk -F '(' '{ print $1; }' | awk -F '=' '{ print $1;
}' > publicized_from_memory.txt
if diff publicized_from_safe.txt publicized_from_memory.txt | grep '>'; then
	echo "Error: std/memory.e symbols not in std/safe.e to all files        ...bad."
	exit 1
else
	echo "The include std/safe.e provides as many symbols as as std/memory.e...good." 
fi
