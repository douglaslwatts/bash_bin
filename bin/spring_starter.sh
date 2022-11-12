#!/bin/bash
#
# Description:
#
# A quick script to grab a Spring Boot project from spring.starter.io
#
# A directory named the value of the project name arg provided will be created in your CWD and the
# project starter will be placed in that directory.
#
# Required flags: -a -> The name of the Application
#                 -b -> The base directory for the project
#                 -g -> The group ID
#                 -i -> The artifact ID
#                 -n -> The name of the project
#                 -p -> The package name for the initial setup of the project
#                 -t -> The type of the project, maven-project|gradle-project
#
# Optional flag:  -d -> A comma separated list of project dependencies for the project starter
#

usage() {
    echo "Usage: $1 -a applicationName -g groupId -i artifactId -n projectName -t projectType -p packageName -b baseDirectory [-d dependency1,dependency2,...,dependencyN]"
    exit 0
}

unset -v app_name
unset -v base_dir
unset -v dependencies
unset -v group_id
unset -v artifact_id
unset -v package_name
unset -v project_name
unset -v project_type

while getopts "a:b:d:g:i:n:p:t:" opt; do
    case $opt in
        a) app_name=${OPTARG};;
        b) base_dir=${OPTARG};;
        d) dependencies=${OPTARG};;
        g) group_id=${OPTARG};;
        i) artifact_id=${OPTARG};;
        n) project_name=${OPTARG};;
        p) package_name=${OPTARG};;
        t) project_type=${OPTARG};;
       \?) echo "Invalid option -${OPTARG}" >&2
           usage ${0};;
        :) echo "Option -${OPTARG} requires an argument" >&2
            usage ${0};;
    esac
done

shift $(( OPTIND - 1 ))

if [ -z "$app_name" ]; then
    echo -e "Missing required argument for application name!\n" >&2
    usage $0
fi

if [ -z "$base_dir" ]; then
    echo -e "Missing required argument for base directory!\n" >&2
    usage $0
fi

if [ -z "$group_id" ]; then
    echo -e "Missing required argument for group ID!\n" >&2
    usage $0
fi

if [ -z "$artifact_id" ]; then
    echo -e "Missing required argument for artifact ID!\n" >&2
    usage $0
fi

if [ -z "$package_name" ]; then
    echo -e "Missing required argument for package name!\n" >&2
    usage $0
fi

if [ -z "$project_name" ]; then
    echo -e "Missing required argument for project name!\n" >&2
    usage $0
fi

if [ -z "$project_type" ]; then
    echo -e "Missing required argument for project type!\n" >&2
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
    readonly CURL_CMD="curl https://start.spring.io/starter.tgz -d applicationName=${app_name} -d artifactId=${artifact_id} -d groupId=${group_id} -d packageName=${package_name} -d type=maven-project -d dependencies=${deps} -d name=${project_name} -d baseDir=${base_dir}"
else
    readonly CURL_CMD="curl https://start.spring.io/starter.tgz -d applicationName=${app_name} -d artifactId=${artifact_id} -d groupId=${group_id} -d packageName=${package_name} -d type=maven-project name=${project_name} -d baseDir=${base_dir}"
fi

readonly TAR_CMD="tar -xzvf -"

#mkdir "${PWD}/${app_name}"
#cd "$app_name"
$CURL_CMD | $TAR_CMD

exit $?

