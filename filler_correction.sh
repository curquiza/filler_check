#!/bin/bash

bin=""
reverse_opt=0
rslt_file="rslt.txt"

# INIT AND PARSING #############################################################

print_title() {
	echo "*************************************" | tee $rslt_file
	echo "***** FILLER_CORRECTION RESULTS *****" | tee -a $rslt_file
	echo "*************************************" | tee -a $rslt_file
}

error_vm() 		{ echo "File filler_vm is missing"; }
error_players() { echo "Folder players is missing"; }
error_maps() 	{ echo "Folder maps is missing"; }
error_script() 	{ echo "File filler_check.sh is missing"; }
error_binary() 	{ echo "Binary invalid"; }

print_usage() { echo 'Usage: sh filler_correction.sh -b [your_binary] [ -r ]'; }

error_exit() {
	($1 1>&2)
	exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

check_presence() {
	local err=0
	if [ ! -f "filler_vm" ] ; then
		local err=1
		error_vm
	fi
	if [ ! -d "players" ] ; then
		local err=1
		error_players
	fi
	if [ ! -d "maps" ] ; then
		local err=1
		error_maps
	fi
	if [ ! -f "filler_check.sh" ] ; then
		local err=1
		error_script
	fi
	if [ $err -eq 1 ] ; then
		exit
	fi
}

options_parsing() {
	local OPTIND
	local OPTARG
	while getopts ":b:r" opt; do
		case ${opt} in
			b)	bin=$OPTARG
				;;
			r)	reverse_opt=1
				;;
			\?)	error_exit print_usage
				;;
			:)	error_exit print_usage
				;;
		esac
	done
	shift $((OPTIND-1)) #remove options got by getopts. common practice.
}

check_parameters() {
	if [ ! -f $bin ] || [ -z $bin ] ; then
		error_exit error_binary
	fi
}

clean() {
	rm -rf trace rslt.txt
}

init() {
	check_presence
	options_parsing $@
	check_parameters
	clean
}

# MAIN #########################################################################

run_correction() {
	for player in players/*.filler ; do
		for map in maps/* ; do
			if [ $reverse_opt -eq 1 ] ; then
				sh filler_check.sh -2 $bin -1 $player -m $map -g 5 -c
			else
				sh filler_check.sh -1 $bin -2 $player -m $map -g 5 -c
			fi
		done
	done
}

init $@
print_title
run_correction
