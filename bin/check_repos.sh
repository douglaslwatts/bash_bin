#!/bin/bash

# Check if any local Git repos are outdated or have uncommitted/unstaged changes in a given
# directory of Git repos.

usage() {
    echo "Usage: $1 -d <project directory>"
}

unset -v project_dir

while getopts "d:h" opt; do
    case $opt in
        d) project_dir=$OPTARG;;
        h) usage $0
           exit 0;;
        \?) usage $0
            exit 1;;
   esac
done

if [ -z "$project_dir" ]; then
    usage $0
    exit 1
fi

if [ ! -d "$project_dir" ]; then
    echo "Error! The directory given is not a directory!" >&2
    usage $0
    exit 1
fi

cd "$project_dir"

for dir in **; do
    if [ -d "$dir" ]; then
        cd $dir

        if [ -d "./.git" ]; then
           attention_needed=0

           if [ "$(git status | grep -o 'Changes ')" != "" ]; then
               attention_needed=1
               echo -e "$dir has uncomitted or unstaged changes in current branch.\n"
               status="$(git status)"
               echo -e "--------------------------------------------------------------------------\
                   \n$status\n\
--------------------------------------------------------------------------\n\n"
           fi

           if [ "$(git remote show origin | grep -o 'local out of date')" != "" ]; then
               attention_needed=1
               echo -e "$dir branch(es) is/are out of date and need a pull!\n"
               status="$(git remote show origin | grep 'local out of date')"
               echo -e "--------------------------------------------------------------------------\
                   \n$status\n\
--------------------------------------------------------------------------\n\n"
           fi

           if [ $attention_needed -eq 0 ]; then
               echo -e "$dir is up to date and has no uncommitted changes : )\n"
           fi
        fi
        cd ..
    fi
done

exit 0

