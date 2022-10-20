#!/bin/bash

# Author: Douglas L. Watts
# Version: 1.0
# Date: 10/16/2022
# File: background_changer.sh
#
# Change the background image periodically, via feh, when using i3wm as a DE.
# Script assumes that there is already a feh exec command in i3 config prior to running this script
# in the form:
#               exec --no-startup-id feh --bg-scale /absolute/path/to/image_file
#
# If that is not the case either make it so or edit the needed grep | cut command in this script to
# match the feh command that is in the i3 config file
#
# NOTE: Most distros come with the commands used here, but make sure you have pgrep, feh, and 
#       ImageMagick for the convert command.
#
# NOTE: Creating the transition imgage files is VERY CPU intensive and the first time this script is
#       run the transition image files for every image in the background images directory will be
#       created (two for the first iteration, then 1 per interval), which will take a while for each
#       interval before the transition can begin This will occur for any image(s) added later as
#       well. An image added during runtime will be added to the current rotation. It will naturally
#       take longer and be more CPU intensive for larger images, while for smaller images
#       (under 500KiB) it is actually quite fast on my system. 
#       Oh, and then there is storage. Currently, there are 9 pictures in my backgrounds directory.
#       1 is under 500Kib, 1 is just under 1MiB, 5 are around 1.5Mib, 1 is 2.2MiB, and 1 is 4.1MiB
#       This has made my background_transitions directory 138MiB. Not too crazy, but I imagine it may
#       not be a great idea to use this on one's entire Pictures directory. Especially if there are
#       thousands of Pictures in it. At this time, only pictures in the base background images
#       directory will be used. I will add the functionality to pick random images from 
#       subdirectories in the future, naturally not getting images from the background_transitions/
#       directory as that would cause issues. I may move the background_transitions/ directory to be
#       a hidden directory in $HOME.
#
# Required Args and the flag to provide them to:
#
#                       -d --> background images directory, relative to your home directory.
#                                       If the files are in /home/username/Pictures/backgrounds/
#                                       then it would be --> -d Pictures/backgrounds
#                       One of -h, -m, -s with hours, minutes, or seconds respectively. This
#                       should be a number of hours, minutes, or seconds for the interval between
#                       image transitions
#
# Optional Arg and the flag to provide it to:
#
#                       -f --> The location of the i3wm config file if not the default location of
#                       $HOME/.config/i3/config
#
# Place the command in .bash_profile or .profile, whichever you use. Don't forget the '&' at the 
# end as the script runs a forever loop to do its job. If you do not you will need to switch to a
# TTY and ctrl-c then add it to the command, which is what I did LOL the first time I ran it :)
# Note the pgrep redirect to /dev/null returns empty so false if there is not a background_changer
# already running from a previous login and non-empty so true otherwise. This prevents having
# more than one instance running if you logout and back in.
#
# example:
#           if [ "${XDG_CURRENT_DESKTOP}" = "i3" ]; then
#               ${HOME}/bin/random_background_image.sh &
#               pgrep -f background_changer.sh &> /dev/null || \
#                   ${HOME}/bin/background_changer.sh -d Pictures/background_images -m 5 &
#           fi
#
# Bonus: use the random_background_image.sh script as well, as not to start with the same image
#        upon each i3 session. so the .bash_profile|.profile command would change to:
#
#           if [ "${XDG_CURRENT_DESKTOP}" = "i3" ]; then
#               ${HOME}/bin/random_background_image.sh &
#               pgrep -f background_changer.sh &> /dev/null || \
#                   ${HOME}/bin/background_changer.sh -d Pictures/background_images -m 5 &
#           fi
#

# Prints a usage message and exits
# Arg: $1 should be the name of this file
usage() {
    echo "Usage: $1 <-d <background_images_dir>> <-h|-m|-s <hours|minutes|seconds>> [-f <i3_config_file>]" >&2
    echo -e "\nNote:"
    echo -e "\tA background image directory and either hours, minutes, or secconds must be given\n" >&2
    echo -e "\tBackground Image Directory must be relative path from ${HOME}\n" >&2
    echo -e "\tIf i3 config file is given, it must also be a relative path from ${HOME}\n" >&2
    echo -e "\tIf no i3 config file is given, ${HOME}/.config/i3/config is assumed\n" >&2
    echo -e "\tIf seconds are less than 30, 30 seconds will be used\n" >&2
    echo -e "\tIf hours or minutes are less than 1, 1 will be used" >&2

    exit 1
}

# Creates a subdirectory within the given background images directory to hold the transition image
# files. If there are quite a lot of images you want for the backgrounds, this will grow quickly as
# almost 100 transition image files are kept for each image file to make the transitions smooth.
# Arg: $1 --> The file name which needs transition files created
# Arg: $2 --> The basename of the file, i.e. picture.jpg basename would be picture
# Arg: $3 --> The file extension of the image file, i.e. .jpg, .png
# Arg: $4 --> The directory to place the transition files within
# Arg: $5 --> The number of transition files to create.
create_transition_files() {
    file_name="$1"
    file_basename="$2"
    file_extension="$3"
    file_dir="$4"
    num_transitions=$5
    # num_blurred=$(( num_transitions / 3 ))

    i=0;

    while [ $i -lt $num_transitions ]; do
        (( i++ ))
        convert -blur 0x${i} "$file_name" "${file_dir}/${file_basename}${i}${file_extension}"
        sleep .2s
        convert "${file_dir}/${file_basename}${i}${file_extension}" \
            -fill black -colorize ${i}% \
            "${file_dir}/${file_basename}${i}${file_extension}"
    done
}

unset -v background_images_dir
unset -v hours_between_transitions
unset -v minutes_between_transitions
unset -v seconds_between_transitions
unset -v i3_config_file

# parse the command line args via getopts

while getopts "d:h:m:s:f:" opt; do
    case $opt in
        d) background_images_dir="${HOME}/${OPTARG}";;
        h) hours_between_transitions=${OPTARG};;
        m) minutes_between_transitions=${OPTARG};;
        s) seconds_between_transitions=${OPTARG};;
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

# Make sure at least one time arg was given for a transition interval

if [ -z "$hours_between_transitions" ] && [ -z "$minutes_between_transitions" ] &&
   [ -z "$seconds_between_transitions" ]; then

   echo "A time argument must be provided via -h, -m, or -s" >&2
   usage $0
fi

# Make sure only one time art was given for a transitional interval

if [[ ! -z "$hours_between_transitions" && ! -z "$minutes_between_transitions" && \
     ! -z "$seconds_between_transitions" ]] || \
   [[ ! -z "$hours_between_transitions" && ! -z "$minutes_between_transitions" ]] || \
   [[ ! -z "$hours_between_transitions" && ! -z "$seconds_between_transitions" ]] || \
   [[ ! -z "$minutes_between_transitions" && ! -z "$seconds_between_transitions" ]]; then

   echo -e "Error! Only specify one of -h, -m, or -s please!\n" >&2
   usage $0
fi

# Set the trantitional interval which was provided

if [ ! -z "$hours_between_transitions" ]; then
    if [ $hours_between_transitions -lt 1 ]; then
        transition_wait_period="1h"
    else
        transition_wait_period="${hours_between_transitions}h"
    fi
elif [ ! -z "$minutes_between_transitions" ]; then
    if [ $minutes_between_transitions -lt 1 ]; then
        transition_wait_period="1m"
    else
        transition_wait_period="${minutes_between_transitions}m"
    fi
elif [ ! -z "$seconds_between_transitions" ]; then
    if [ $seconds_between_transitions -lt 30 ]; then
        transition_wait_period="30s"
    else
        transition_wait_period="${seconds_between_transitions}s"
    fi
fi

# Make sure the images directory given actually exists

if [ ! -d "$BACKGROUNDS_DIR" ]; then
    echo -e "Error! Given background images directory:\n${BACKGROUNDS_DIR}" >&2
    echo -e "does not exist or exists but is not a directory!\n" >&2
    usage $0
fi

# Make sure we have permissions to read/write from/to the images directory given

if [ ! -w "$BACKGROUNDS_DIR" ] || [ ! -r "$BACKGROUNDS_DIR" ]; then
    echo -e "Error! You do not have permissions to read and/or write to:\n${BACKGROUNDS_DIR}\n" >&2
    usage $0
fi

# create a subdirectory for transition files if it does not exist

readonly TRANSITIONS_DIR="${BACKGROUNDS_DIR}/background_transitions"

if [ ! -d "${TRANSITIONS_DIR}" ]; then
    mkdir "${TRANSITIONS_DIR}"
fi

# get the current background image file absolute path from the i3 config file

# command in i3 config file should be as below, or change below grep | cut to match it
# exec --no-startup-id feh --bg-scale /absolute/path/to/image_file

old_file_name="$(grep 'id feh' $I3_CONFIG_FILE | cut -d' ' -f5)"

# a variable to hold the previouse index in the file image array, as not to choose the same
# picture that is already set when transitioning

old_index=0

# set the number of transition files

readonly NUM_TRANSITIONS=95

while [ true ]; do
    sleep $transition_wait_period

    # build an array of absolute paths to the image files see how many there are and choose a random
    # array index

    background_images_array=(${BACKGROUNDS_DIR}/*)
    num_images="${#background_images_array[@]}"
    random_index=$(( $RANDOM % $num_images ))

    # make sure to get an index that was not chosen last time around

    while [ $random_index -eq $old_index ]; do
        random_index=$(( $RANDOM % $num_images ))
    done

    # save the index chosen this time, to use next time in above check

    old_index=$random_index

    # get the absolute path to the new background image to transition to, from the array
    # get the basename, file extension, and transition file directory for new background image

    new_file_name="${background_images_array[${random_index}]}"

    # If we get the background_transitions/ directory, throw it away and grab an image file instead

    while [ -d "$new_file_name" ]; do
        random_index=$(( $RANDOM % $num_images ))

        while [ $random_index -eq $old_index ]; do
            random_index=$(( $RANDOM % $num_images ))
        done

        old_index=$random_index
        new_file_name="${background_images_array[${random_index}]}"
    done

    # get the basename, file extension, and transition file directory for current background image

    old_file_basename=$(basename $old_file_name | grep -oE '^[^\.]+')
    old_file_extension="$(basename $old_file_name | grep -oE '[\.].*')"
    old_file_transitions_dir="${TRANSITIONS_DIR}/${old_file_basename}"

    new_file_basename=$(basename $new_file_name | grep -oE '^[^\.]+')
    new_file_extension="$(basename $new_file_name | grep -oE '[\.].*')"
    new_file_transitions_dir="${TRANSITIONS_DIR}/${new_file_basename}"

    # If there is not already a directory of transition file for either the current or new
    # background image file, then create the directory and the transition files

    i=0;
    j=0

    if [ ! -d ${old_file_transitions_dir} ]; then
        mkdir $old_file_transitions_dir
        create_transition_files $old_file_name $old_file_basename $old_file_extension \
                                $old_file_transitions_dir $NUM_TRANSITIONS
    fi

    if [ ! -d ${new_file_transitions_dir} ]; then
        mkdir $new_file_transitions_dir
        create_transition_files $new_file_name $new_file_basename $new_file_extension \
                                $new_file_transitions_dir $NUM_TRANSITIONS
    fi

    # loop through and have feh set the transition files one by one, effectively transitioning from
    # the current background image to the new one

    i=1

    while [ $i -lt $NUM_TRANSITIONS ]; do
        feh --bg-scale "${old_file_transitions_dir}/${old_file_basename}${i}${old_file_extension}"
        (( i++ ))
    done

    while [ $i -gt 0 ]; do
        feh --bg-scale "${new_file_transitions_dir}/${new_file_basename}${i}${new_file_extension}"
        (( i-- ))
    done

    # set the new background image

    feh --bg-scale $new_file_name

    # save the new background image file as the old one for the next iteration

    old_file_name="$new_file_name"
done

exit 0

