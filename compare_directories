#!/bin/bash

####################################################################################################
# This script will compare two directories given an args.
#
# Note: this is mostly useful for calling from another script which needs to compare directories
#
# Author:  Lee Watts
# Date:    02/24/2021
#
# exit status: 0 --> if directories are the same
#              1 --> if directories are not the same
#              2 --> incorrect number of args
#              3 --> one or more of the directories does not have read permissions
#              4 --> one or more of the directories does not exists
#              5 --> one or more of the directories is not a directory
####################################################################################################

[ $# -ne 2 ] && exit 2

[ ! -r "$1" ] || [ ! -r "$2" ] && exit 3
[ ! -e "$1" ] || [ ! -e "$2" ] && exit 4
[ ! -d "$1" ] || [ ! -d "$2" ] && exit 5

dir_1="$1"
dir_2="$2"
sha1_dir_1=$(find "$dir_1" -type f \( -exec sha1sum {} \; \) | awk '{print $1}' | sort | sha1sum)
sha1_dir_2=$(find "$dir_2" -type f \( -exec sha1sum {} \; \) | awk '{print $1}' | sort | sha1sum)

[ "$sha1_dir_1" = "$sha1_dir_2" ] && exit 0
[ "$sha1_dir_1" != "$sha1_dir_2" ] && exit 1
