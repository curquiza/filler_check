#!/bin/bash

p1=""
p2=""
games="5"
map=""
correction_opt=0
alternate_opt=0
rslt_file="rslt.txt"
debug_folder="trace"
score_p1=0
score_p2=0

DEF='\e[m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'

## TOOLS FUNCTIONS #############################################################

print_title() {
	echo "*************************************" | tee $rslt_file
	echo "******** FILLER_TEST RESULTS ********" | tee -a $rslt_file
	echo "*************************************" | tee -a $rslt_file
}

print_game_start() {
	echo "\n*** $p1_basename VS $p2_basename - $map_basename ***" | tee -a $rslt_file
}

print_rslt() {
	local winner=`grep won filler.trace`
	local rslt=`grep AGAINST filler.trace`
	printf "%-5s" "$1"
	echo "$winner - $rslt" | tee -a $rslt_file
}

print_error() {
	local segfault=`grep "Segfault" filler.trace`
	local buse=`grep "Bus error" filler.trace`
	local timeout=`grep "timedout" filler.trace`
	local error=""
	if [ ! -z "$segfault" ] ; then
		local error=$segfault
	elif [ ! -z "$buse" ] ; then
		local error=$buse
	elif [ ! -z "$timeout" ] ; then
		local error=$timeout
	fi
	if [ ! -z "$error" ] ; then
		printf "$RED    %s$DEF\n" "$error"
	fi
}

print_usage() { echo 'Usage: sh filler_check.sh -1 [player] -2 [player] -m [map] [ -g [nb_games] -a ]'; }

error_file() { echo "Valid $1 file needed"; }

error_vm() { echo "File filler_vm is missing"; }

error_exit() {
	($1 1>&2)
	exit "${2:-1}"  ## Return a code specified by $2 or 1 by default.
}

print_final_rslt() {
	local color_p1=$DEF
	local color_p2=$DEF
	if [ $score_p1 -eq $games ] ; then
		local color_p1=$GREEN
	elif [ $score_p2 -eq $games ] ; then
		local color_p2=$GREEN
	else
		if [ $score_p1 -ge $score_p2 ] ; then
			local color_p1=$YELLOW
		fi
		if [ $score_p2 -ge $score_p1 ] ; then
			local color_p2=$YELLOW
		fi
	fi
	printf "\n$color_p1%-10s %s/%s$DEF\n" $p1_basename $score_p1 $games | tee -a $rslt_file
	printf "$color_p2%-10s %s/%s$DEF\n" $p2_basename $score_p2 $games | tee -a $rslt_file
}

## INIT #########################################################################

check_vm() {
	if [ ! -f "filler_vm" ] ; then
		error_exit error_vm
	fi
}

options_parsing() {
	local OPTIND
	local OPTARG
	while getopts ":1:2:m:g:ac" opt; do
		case ${opt} in
			1)	p1=$OPTARG
				;;
			2)	p2=$OPTARG
				;;
			m)	map=$OPTARG
				;;
			g)	games=$OPTARG
				;;
			a)	alternate_opt=1
				;;
			c)	correction_opt=1
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
	local err=0
	if [ ! -f $map ] || [ -z $map ] ; then
		error_file 'map'
		local err=1
	fi
	if [ ! -f $p1 ] || [ -z $p1 ] ; then
		error_file 'player 1'
		local err=1
	fi
	if [ ! -f $p2 ] || [ -z $p2 ] ; then
		error_file 'player 2'
		local err=1
	fi
	reg='^[0-9]+$'
	if ! [[ $games =~ $reg ]] ; then
		echo "Number of games must be a positiv numeric value"
		local err=1
	elif [ $games -gt 1000 ] || [ $games -le 0 ]  ; then
		echo "The number of games must be greater than 0 and less or equal than 1000"
		local err=1
	fi
	if [ $err -eq 1 ] ; then
		exit
	fi
}

init_basenames() {
	local tmp=${p1##*/}
	p1_basename=${tmp%.filler}
	local tmp=${p2##*/}
	p2_basename=${tmp%.filler}
	map_basename=${map##*/}
}

del_old_files() {
	rm -rf $debug_folder
	rm -rf $rslt_file
}

init() {
	check_vm
	options_parsing $@
	check_parameters
	if [ $correction_opt -eq 0 ] ; then del_old_files ; fi
	init_basenames
}

## DEBUG FILES #################################################################

init_debug_path() {
	debug_path="$debug_folder/$p1_basename-$p2_basename/$map_basename/$1"
	mkdir -p $debug_path
}

copy_debug() {
	cp filler.trace $debug_path
	if [ -f debug_init ] ; then
		cp debug_init $debug_path #perso
	fi
	if [ -f debug_strat_map ] ; then
		cp debug_strat_map $debug_path #perso
	fi
}

## MAIN FUNCTIONS ##############################################################

switch_players() {
	local tmp_player=$p1
	local tmp_basename=$p1_basename
	p1=$p2
	p1_basename=$p2_basename
	p2=$tmp_player
	p2_basename=$tmp_basename
}

score_counter() {
	if [ `grep "$p1 won" filler.trace | wc -l | tr -d ' '`  -gt 0 ] ; then
		let score_p1=$score_p1+1
	fi
	if [ `grep "$p2 won" filler.trace | wc -l | tr -d ' '`  -gt 0 ] ; then
		let score_p2=$score_p2+1
	fi
}

run_games() {
	for i in `seq 1 $games`
	do
		init_debug_path $i
		./filler_vm -f $map -p1 $p1 -p2 $p2 > "$debug_path/game.txt"
		copy_debug
		print_rslt $i
		print_error
		score_counter
	done
}

init $@
if [ $correction_opt -eq 0 ] ; then print_title ; fi #correction
print_game_start
run_games
print_final_rslt
if [ $alternate_opt -eq 1 ] ; then
	score_p1=0
	score_p2=0
	switch_players
	print_game_start
	run_games
	print_final_rslt
fi
