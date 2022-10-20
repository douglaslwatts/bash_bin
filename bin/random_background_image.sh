#!/bin/bash
#
# Author: Douglas L. Watts
# Version: 1.0
# Date: 10/16/2022
# File: random_background_image.sh
#
# Example:
#
#   Place below in .bash_profile or .profile, whichever is relavent to you
#
#       if [ "${XDG_CURRENT_DESKTOP}" = "i3" ]; then
#           ${HOME}/bin/random_background_image.sh -d Pictures/background_images &
#       fi
#
 
# Prints a usage message and exits
# Arg: $1 should be the name of this file
usage() {
    echo "Usage: $1 <-d <background_images_dir>> [-f <i3_config_file>]" >&2
    echo -e "\tIf i3 config file is given, it must also be a relative path from ${HOME}\n" >&2
    echo -e "\tIf no i3 config file is given, ${HOME}/.config/i3/config is assumed\n" >&2

    exit 1
}

unset -v background_images_dir
unset -v i3_config_file

# parse the command line args via getopts

while getopts "d:h:m:s:f:" opt; do
    case $opt in
        d) background_images_dir="${HOME}/${OPTARG}";;
        f) i3_config_file="${HOME}/${OPTARG}";;
        \?) echo "Invalid option: -${OPTARG}" >&2
            usage ${0};;
        :) echo "Option -${OPTARG} requires an argument!" >&2
            usage ${0};;
    esac
done

shift "$(( OPTIND - 1 ))"

# Make sure that a image directory arg was provided

if [ -z "$background_images_dir" ]; then
    echo -e "Missing required Argument for background images directory!\n" >&2
    usage $0
else
    readonly BACKGROUNDS_DIR="${background_images_dir}"
fi

# if an i3 config file was provided, set that, otherwise use the default i3 config location

if [ -z "$i3_config_file" ]; then
    readonly I3_CONFIG_FILE="${HOME}/.config/i3/config"
else
    readonly I3_CONFIG_FILE="${HOME}/${i3_config_file}"
fi

#readonly BACKGROUNDS_DIR="${HOME}/Pictures/background_images"
readonly BACKGROUND_IMAGES_ARRAY=(${BACKGROUNDS_DIR}/*)
readonly NUM_IMAGES="${#BACKGROUND_IMAGES_ARRAY[@]}"
readonly RANDOM_INDEX=$(( $RANDOM % $NUM_IMAGES ))
readonly FILE_NAME="${BACKGROUND_IMAGES_ARRAY[${RANDOM_INDEX}]}"

# Make sure we get a file not a subdirectory

while [ -d "${FILE_NAME}" ]; do
    readonly RANDOM_INDEX=$(( $RANDOM % $NUM_IMAGES ))
    readonly FILE_NAME="${BACKGROUND_IMAGES_ARRAY[${RANDOM_INDEX}]}"
done

readonly FEH_COMMAND="exec --no-startup-id feh --bg-scale"
#readonly I3_CONFIG_FILE="${HOME}/.config/i3/config"

sed -i "s:\(${FEH_COMMAND}\) .*:\1 ${FILE_NAME}:" $I3_CONFIG_FILE

exit 0

