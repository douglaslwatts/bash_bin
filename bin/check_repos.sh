#!/bin/bash

# A quick dirty script to see if any local Git repos are outdated.

usage() {
    echo "Usage: $0 -d <project directory>"
}

unset -v project_dir

while getopts "d:h" opt; do
    case $opt in
        d) project_dir=$OPTARG;;
        h) usage $0
           exit 0;;
        \?) echo "Invalid option: -${OPTARG}" >&2
            usage $0
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
        if [ -d "./.git" ] &&
           [ "$(git status | grep -o 'Your branch is up to date with')" == "" ]; then
            echo -e "$dir is outdated and needs a pull or has uncomitted changes in branch.\n"
            status="$(git status)"
            echo -e "---------------------------------\n$status\n---------------------------------\n\n"
        fi
        cd ..
    fi
done

exit 0

