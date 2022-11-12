#!/bin/bash
#
# Description:
#
# A quick script to grab a Spring Boot project from spring.starter.io
#
# A directory named the value of the project name arg provided will be created in your CWD and the
# project starter will be placed in that directory.
#
# Required flag: -n -> The name of the project
#
# Optional flag:  -d -> A comma separated list of project dependencies for the project starter
#

usage() {
    echo "Usage: $1 <-n projectName> [-d dependency1,dependency2,...,dependendyN]"
    exit 0
}

unset -v project_name
unset -v dependencies

while getopts "n:d:" opt; do
    case $opt in
        n) project_name=${OPTARG};;
        d) dependencies=$OPTARG;;
       \?) echo "Invalid option -${OPTARG}" >&2
           usage ${0};;
        :) echo "Option -${OPTARG} requires an argument" >&2
            usage ${0};;
    esac
done

shift $(( OPTIND - 1 ))

if [ -z "$project_name" ]; then
    echo -e "Missing required argument for project name!\n" >&2
    usage $0
fi

num_deps=${#dependencies[@]}
i=0
deps=""

while [ $i -lt $num_deps ]; do
    deps=${deps}${dependencies[$i]}
    (( i++ ))

    if [ $i -lt $num_deps ]; then
        deps=${deps},
    fi
done

if [ ! -z "${dependencies}" ]; then
    readonly CURL_CMD="curl https://start.spring.io/starter.tgz -d dependencies=${deps} -d name=${project_name}"
else
    readonly CURL_CMD="curl https://start.spring.io/starter.tgz name=${project_name}"
fi

readonly TAR_CMD="tar -xzvf -"

mkdir "${PWD}/${project_name}"
cd "$project_name"
$CURL_CMD | $TAR_CMD

exit $?

