#!/bin/bash

####################################################################################################
# Author: Lee Watts
# Date:   07/24/2021
#
# Description: This is a script which checks that two given directories have identical contents. If
#              the contents differ, then there is an option to sync them keeping one directory or
#              the other's contents. If they are identical, then this is reported.
#
#              Note: the compare_directories.sh script should be placed in one's ~/bin directory for
#                    this script to work.
#
# Exit Status: 0 --> Success
#              1 --> usage error
#              2 --> Required script "compare_directories" has incorrect permissions or is absent
#              3 --> one or more of the directories does not exists
#              4 --> one or more of the directories is not a directory
#              5 --> one or more of the directories does not have read permissions
#              6 --> One of the given directories has no write permissions
#              7 --> An unknown error occured
####################################################################################################

if [ $# -ne 2 ]; then
    echo "Compare 2 directories to see if they have identical content, with the option to" >&2
    echo -e "sync them, keeping the contents of one or the other.\n" >&2
    echo "Usage: $0 <directory 1> <directory 2>" >&2
    exit 1
fi

readonly DIR_CHECKER="/home/${USER}/bin/compare_directories.sh"

if [ ! -f "$DIR_CHECKER" ] || [ ! -x "$DIR_CHECKER" ] || [ ! -r "$DIR_CHECKER" ]; then
    echo "Error: $DIR_CHECKER is a script which is required for $0 to function correctly." >&2
    [ -f "$DIR_CHECKER" ] && [ ! -x "$DIR_CHECKER" ] && \
        echo "Please add execute permission to $DIR_CHECKER" >&2
    [ -f "$DIR_CHECKER" ] && [ ! -r "$DIR_CHECKER" ] && \
        echo "Please add read permission to $DIR_CHECKER" >&2
    [ ! -f "$DIR_CHECKER" ] && echo "$DIR_CHECKER is not a regular file" >&2
    exit 2
fi

dir_1="$1"
dir_2="$2"

$DIR_CHECKER "$dir_1" "$dir_2"
directories_are_same="$?"

{
    if [ $directories_are_same -eq 3 ]; then
        echo "One of the directories $dir_1 and $dir_2 does not exist!"
        exit $directories_are_same
    elif [ $directories_are_same -eq 4 ]; then 
        echo "One of the directories $dir_1 and $dir_2 is not a directory!"
        exit $directories_are_same
    elif [ $directories_are_same -eq 5 ]; then
        echo "One of the directories $dir_1 and $dir_2 does not have read permissions!"
        exit $directories_are_same
    fi
} >&2

if [ $directories_are_same -eq 0 ]; then
    echo "The directories $dir_1 and $dir_2 contain identical content"
elif [ $directories_are_same -eq 1 ]; then
    echo "The directories $dir_1 and $dir_2 do not contain identical content"
    read -p "Would you like to sync the directories(choose which to keep next)? (y/n) " sync_dirs
    echo

    if [ "$sync_dirs" == "y" ]; then

        if [ ! -w "$dir_1" ] || [ ! -w "$dir_2" ]; then
            [ ! -w "$dir_1" ] && echo "Error! $USER has no write permissions for $dir_1"
            [ ! -w "$dir_2" ] && echo "Error! $USER has no write permissions for $dir_2"
            exit 6
        fi

        echo -en "Keep which directory's contents?\n\n0-> quit\n1-> ${dir_1}\n2-> ${dir_2}\n\n> "
        read keep_dir
        while [ "$keep_dir" -ne 0 ] && [ "$keep_dir" -ne 1 ] && [ "$keep_dir" -ne 2 ]; do
            echo -e "\nInvalid choice! Please try again or enter 0 to quit!\n" >&2
            echo -en "Keep which directory's contents?\n\n0-> quit\n1-> ${dir_1}\n2-> ${dir_2}\n\n> "
            read keep_dir
        done

        if [ "$keep_dir" -eq 1 ] || [ "$keep_dir" -eq 2 ]; then

            result=1
            [ "$keep_dir" -eq 1 ] && rsync -r --delete "${dir_1}/" "${dir_2}/" && result="$?"
            [ "$keep_dir" -eq 2 ] && rsync -r --delete "${dir_2}/" "${dir_1}/" && result="$?"

            if [ "$result" -eq 0 ]; then
                echo -e "\nSuccess! $dir_1 and $dir_2 are synced."
            else
                echo "There was some issue in syncing, review the output for further details" >&2
            fi
        fi
    fi
else
    echo "Error! Something unknown went wrong. Directories $dir_1 and $dir_2 are unaltered." >&2
    exit 7
fi

exit 0
