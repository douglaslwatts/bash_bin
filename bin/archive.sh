#!/bin/bash

# Author: Douglas L. Watts
# Date:   04/18/2021
#
# Archives m subdirectories within n directories given as CLI args. If any subdirectories are
# already archived using bzip, then a warning is printed and they not archived. The total number
# of subdirectories which were not archived are reported for each directory.
#
# return value: 0  if all subdirectories were archived
#               number of subdirectories which were already archived
#               99 if invalid usage

if [ $# -eq 0 ]; then
    echo "Usage: $0 <dir> [dir ...]"
    exit 99
fi

exitval=0

while [ $# -ne 0 ]; do
    directory="$1"
    count=0
    for dir in "$directory"/*; do
        if [ -d "$dir" ]; then
            if [ -e "${dir}.tbz" ]; then
                echo "Warning: ${dir}.tbz already exists, not archiving $dir" >&2
                (( exitval++ ))
                (( count++ ))
            else
                tar -cjf "${dir}.tbz" "$dir"
            fi
        fi
    done

    if [ $count -ne 0 ]; then
        echo "Did not archive $count subdirectories in $directory!" >&2
    fi

    shift 1
done

exit "$exitval"
