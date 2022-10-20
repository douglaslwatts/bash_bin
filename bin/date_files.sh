#!/bin/bash

####################################################################################################
# Author: Douglas L. Watts
# Date:   05/17/2020
#
# Description: This is a scrpt which will add the current date between the filename and the
# extension of any file argument(s) and/or all files in any directory argument(s) recursively.
#
# Exit Status: 0 => success, dates added to files
#              1 => Incorrect usage of the script, a usage error is printed
####################################################################################################

# Prints a usage message and exits.
function usage() {
    echo -e "Usage: $0 <fie|directory> [file|directory] ...\n" >&2
    echo -ne "$0 accepts any number of file and/or directory arguments.\nThe current date" >&2
    echo -n " will be added between the filename and the file extension of all" >&2
    echo -e " file\narguments. This is done recursively for all directory arguments." >&2
    exit 1
}

# Adds the current date between a file name and a file extension.
# arg: $1 should be a regular file with write permissions
#
# return: 0 => success
#         1 => no arg supplied
#         2 => file is not a regular file
#         3 => file does not have write permissions
function add_date_to_file() {
    [ $# -ne 1 ] && return 1

    if [ ! -f "$1" ]; then
        echo "Error! $1 is not a regular file, date not added to file name!" >&2
        return 2
    fi

    if [ -w "$1" ]; then

        # Get the file extension and path to the file. I still find it interesting that we can
        # nest double quotes within double quotes when using command substitution and it is
        # absolutely neccessary here in the unfortunate case that some filenames have spaces in 
        # them.

        extension="$(echo "$1" | xargs -I x basename x | grep -o "\..*")"
        path="$(dirname "$1")"

        # rename the file placing the current date before the file extension or at the end of
        # the file name if there is no file extension

        mv -v "$1" "${path}/$(basename -s .${extension} "$1")-$(date +%A-%B-%d-%Y)${extension}"
    else
        echo "Error! No write permissions for $1, date not added to file name!" >&2
        return 3
    fi
    return 0
}

# Adds the current date between a file name and a file extension or does so recursively for all
# files in a directory.
#
# arg: $1 should be a regular file or a directory
#
# return: 0 => success
#         1 => no arg supplied
#         2 => file or directory does not exist
#         3 => file is not a regular file or a directory
function add_date() {
    [ $# -ne 1 ] && return 1

    if [ ! -e "$1" ]; then
        echo "No such file or directory: $1" >&2
        return 2
    elif [ ! -f "$1" ] && [ ! -d "$1" ]; then
        echo "Error! $1 exists, but is not a directory or a regular file!" >&2
        return 3
    fi
    
    if [ -f "$1" ]; then
        add_date_to_file "$1"
    elif [ -d "$1" ]; then
        for entry in "$1"/*; do
            if [ -f "$entry" ]; then
                add_date_to_file "$entry"
            elif [ -d "$entry" ]; then
                add_date "$entry"
            fi
        done
    fi
    return 0
}

[ $# -lt 1 ] && usage

shopt -s nullglob

for item in "$@"; do
    [ -h $item ] && continue
    add_date "$item"
done

exit 0
