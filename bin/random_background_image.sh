#!/bin/bash
#
# Author: Douglas L. Watts
# Version: 1.0
# Date: 10/16/2022
# File: random_background_image.sh
#
# Choose a random image from a given background images directory upon each i3 session. For use when
# using i3wm as a DE.
#
# NOTE: The script assumes you have a feh command in i3 config file as below:
#
#       exec --no-startup-id feh --bg-scale /path/to/image_file
#
#       and that the file specified in that command exists. If that is not the case make it so or
#       change the value of the variable FEH_COMMAND in this script
#
# Example:
#
#   Place below in .bash_profile, .profile, .zprofile, etc. whichever is relavent to you. If you
#   startx manually, the same can be placed in .xinitrc
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

# Recursively get a random file name from within a directory tree.
#
# Arg: $1 should be the name of the directory from which to get a file name
# Arg: $2 should be the index within that directory to start with, if the name at that index is
#      a file then return it (i.e., base case met), if it is a directory start recursion
# Arg: $3 should be a default file to use in case of encountering an empty directory during
#      recursion, i.e. a fall back to ensure the base case is eventually met
get_random_image() {
    local backgrounds_dir="$1"
    local backgrounds_array=(${backgrounds_dir}/*)
    local index=$2
    local default_image="$3"

    local file_or_dir="${backgrounds_array[${index}]}"

    if [ ! -f "$file_or_dir" ] && [ ! -d "$file_or_dir" ]; then
        file_or_dir="$default_image"
    fi

    if [ -d "$file_or_dir" ]; then
        backgrounds_dir="$file_or_dir"
        backgrounds_array=(${backgrounds_dir}/*)
        local array_size="${#backgrounds_array[@]}"
        local random_array_index=$(( $RANDOM % $array_size ))

        file_or_dir="$(get_random_image $backgrounds_dir $random_array_index $default_image)"
    fi

    echo "$file_or_dir"
}

unset -v background_images_dir
unset -v i3_config_file

# parse the command line args via getopts

while getopts "d:f:" opt; do
    case $opt in
        d) background_images_dir="${HOME}/${OPTARG}";;
        f) i3_config_file="${HOME}/${OPTARG}";;
        \?) usage ${0};;
        :) usage ${0};;
    esac
done

shift "$(( OPTIND - 1 ))"

# Make sure that an image directory arg was provided

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

readonly BACKGROUND_IMAGES_ARRAY=(${BACKGROUNDS_DIR}/*)
readonly NUM_IMAGES="${#BACKGROUND_IMAGES_ARRAY[@]}"
readonly RANDOM_INDEX=$(( $RANDOM % $NUM_IMAGES ))
readonly DEFAULT_FILE_NAME="$(grep 'id feh' $I3_CONFIG_FILE | cut -d' ' -f5)"
readonly FILE_NAME="$(get_random_image $BACKGROUNDS_DIR $RANDOM_INDEX $DEFAULT_FILE_NAME)"
readonly FEH_COMMAND="exec --no-startup-id feh --bg-scale"

sed -i "s:\(${FEH_COMMAND}\) .*:\1 ${FILE_NAME}:" $I3_CONFIG_FILE

exit 0

