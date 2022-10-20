#!/bin/bash

####################################################################################################
# Author:     Lee Watts
# Date:       03/24/2021
#
# Description: This is a script which will check that a file exists, is a regular file, and has
#              read and, if -w flag is given, write permissions. There are descriptive error
#              messages as well as exit codes to inform the user of what is not acceptable about
#              the file if the file is not acceptable for some reason.
#
# Note: This is mostly useful for calling from another script which needs to check file permissions
#
# Flags: optionally supply -w after all args to check for write permissions as well
#
# Exit Codes: 1 => incorrect usage of this script
#             2 => the file exists, but is not a regular file
#             3 => the file is otherwise not accessible
#             4 => the file has no read and/or write permissions, check the accompanying error
#                  message for further distinction
####################################################################################################

# Prints a usage message and exits the program with status 1
# arg: $1 should be the name of the program
usage() {
    echo "Usage: $1 <filename> [-w]" >&2
    exit 1
}

w_flag="0"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage $0
    exit 1
else
    readonly FILE_NAME="$1"
    if [ $# -eq 2 ]; then
        if [ "$2" != "-w" ]; then
            echo "Invalid flag $2" >&2
            usage $0
        else
            w_flag="1"
        fi
    fi
fi

if [ ! -f "$FILE_NAME" ]; then
    if [ -e "$FILE_NAME" ]; then
        echo "Error: $FILE_NAME is not a regular file" >&2
        exit 2
    else
        echo "Error: $FILE_NAME is not accessible" >&2
        exit 3
    fi
fi

if [ ! -r "$FILE_NAME" ] || [ ! -w "$FILE_NAME" ]; then

    read_perm="1"
    write_perm="1"
    [ ! -r "$FILE_NAME" ] && read_perm="0"
    [ ! -w "$FILE_NAME" ] && write_perm="0"

    [ "$read_perm" -eq 0 ] && echo "$FILE_NAME does not have read permissions" >&2

    if [ "$w_flag" -eq 1 ] && [ "$write_perm" -eq 0 ]; then
        echo "$FILE_NAME does not have write permissions" >&2
    fi

    [ "$read_perm" -eq 0 ] && exit 4
    [ "$w_flag" -eq 1 ] && [ "$write_perm" -eq 0 ] && exit 4
fi

exit 0
