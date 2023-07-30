#!/bin/bash

# Author: Douglas L. Watts
# Version: 1.0
# Date: 07/30/2023
# File: new_package_install.sh
#
# Description:
#       Installs a package or a new version of a package such as an AppImage file.
#
# Args and the flag to provide them to:
#
#       -d --> The absolute path for the destination directory in which to install the package
#       -h --> Print the usage message
#       -p --> The path from $HOME to the package file to install, e.g. Downloads/package.AppImage
#       -u --> The name of your directory within /home, e.g. for /home/tux it would be '-u tux'

unset -v package_file
unset -v destination_dir
unset -v username

usage_message() {
    echo -e "\nUsage: $0 -p <package file path> -d <destination directory> -u <username>\n"
    echo -e "\t-d --> The absolute path for the destination directory in which to install the package"
    echo -e "\t-h --> Print the usage message"
    echo -e "\t-p --> The path from \$HOME to the package file to install, e.g. Downloads/package.AppImage"
    echo -e "\t-u --> The name of your directory within /home, e.g. for /home/tux it would be '-u tux'"
}

usage_error() {
    usage_message $0 >&2
    exit 1
}

usage_info() {
    usage_message $0
    exit 0
}

while getopts "d:hp:u:" opt; do
    case $opt in
        d) destination_dir="$OPTARG";;
        h) usage_info $0;;
        p) package_file="$OPTARG";;
        u) username="$OPTARG";;
        \?) echo "Invalid option: -${OPTARG}" >&2
            usage_error $0;;
        :) echo "Option -${OPTARG} requires an argument!" >&2
            usage_error $0;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$destination_dir" ]; then
    echo -e "Missing required argument for destination directory!\n" >&2
    usage_error $0
fi

if [ -z "$package_file" ]; then
    echo -e "Missing required argument for package file!\n" >&2
    usage_error $0
fi

if [ -z "$username" ]; then
    echo -e "Missing required argument for username!\n" >&2
    usage_error $0
fi

package_file_full_path="/home/${username}/${package_file}"
package_file_basename=$(basename $package_file_full_path)

mv $package_file_full_path $destination_dir
chown root:root ${destination_dir}/$package_file_basename
chmod 755 ${destination_dir}/$package_file_basename

exit $?

