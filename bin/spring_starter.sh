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
#                 -D -> The project description
#                 -h -> show help message
#

# Prints a usage message
# Arg: $1 should be the name of the script
usage() {
    echo "Usage: $1 -a applicationName -g groupId -i artifactId -n projectName -t projectType -p packageName -b baseDirectory [-d dependency1,dependency2,...,dependencyN] [-D projectDescription]"

    echo '''
Required flags: -a -> The name of the Application
                -b -> The base directory for the project
                -g -> The group ID
                -i -> The artifact ID
                -n -> The name of the project
                -p -> The package name for the initial setup of the project
                -t -> The type of the project, maven-project|gradle-project

Optional flag:  -d -> A comma separated list of project dependencies for the project starter
                -D -> The project description
                -h -> show help message
'''
}

# Shows a usage message and exits with status 1
# Arg: $1 should be the name of the script
show_error() {
    usage $1
    exit 1
}

# Shows a usage message and exits with status 0
# Arg: $1 should be the name of the script
show_help() {
    usage $1
    exit 0
}

unset -v app_name
unset -v base_dir
unset -v dependencies
unset -v description
unset -v group_id
unset -v artifact_id
unset -v package_name
unset -v project_name
unset -v project_type

# Set up variables based on the CLI args.

while getopts "a:b:d:D:g:hi:n:p:t:" opt; do
    case $opt in
        a) app_name=${OPTARG};;
        b) base_dir=${OPTARG};;
        d) dependencies=${OPTARG};;
        D) description="${OPTARG}";;
        g) group_id=${OPTARG};;
        h) show_help $0;;
        i) artifact_id=${OPTARG};;
        n) project_name=${OPTARG};;
        p) package_name=${OPTARG};;
        t) project_type=${OPTARG};;
       \?) show_error ${0};;
        :) show_error ${0};;
    esac
done

shift $(( OPTIND - 1 ))

# Make sure required args were present

if [ -z "$app_name" ]; then
    echo -e "Missing required argument for application name!\n" >&2
    show_error $0
fi

if [ -z "$base_dir" ]; then
    echo -e "Missing required argument for base directory!\n" >&2
    show_error $0
fi

if [ -z "$group_id" ]; then
    echo -e "Missing required argument for group ID!\n" >&2
    show_error $0
fi

if [ -z "$artifact_id" ]; then
    echo -e "Missing required argument for artifact ID!\n" >&2
    show_error $0
fi

if [ -z "$package_name" ]; then
    echo -e "Missing required argument for package name!\n" >&2
    show_error $0
fi

if [ -z "$project_name" ]; then
    echo -e "Missing required argument for project name!\n" >&2
    show_error $0
fi

if [ -z "$project_type" ]; then
    echo -e "Missing required argument for project type!\n" >&2
    show_error $0
fi

# Set up the curl command using the required CLI args

curl_cmd="curl https://start.spring.io/starter.tgz -d applicationName=${app_name} -d artifactId=${artifact_id} -d groupId=${group_id} -d packageName=${package_name} -d type=${project_type} -d name=${project_name} -d baseDir=${base_dir}"

# Add any dependencies specified in the CLI args

[ ! -z "${dependencies}" ] && curl_cmd+=" -d dependencies=${dependencies}"

readonly TAR_CMD="tar -xzvf -"

# Run the curl command piped into the tar command so we just leave the project directory in PWD

$curl_cmd | $TAR_CMD

# Replace the default description with the CLI arg description, if provided. There is nowhere that
# the description is used if project type is Gradle, as far as I can tell.

if [ ! -z "$description" ] && [ "$project_type" == "maven-project" ]; then
    sed -i "s:\(<description>\).*\(</description>\):\1${description}\2:" "${PWD}/${base_dir}/pom.xml"
fi

exit $?

