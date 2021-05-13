#! /bin/sh -
#
####################
#
# dcm: Dynamic Colour Mapping

TTY=$(tty| sed -e 's,/dev/,,' -e 's,/,_,g');
PROG=$(basename $0);
LOCK=${HOME}/.pid.dcolor.${TTY};
VERSION="dcm 4.0 2021-05-13 greywolf@starwolf.com";
MAPPATH="@LIBDIR@/dmap";

search() {	# usage: search path item; path is colon-separated
    local suf path item d f OIFS rs;
    if [ $1x = -xx ]; then {
	shift;
	suf=$1;
	shift;
    } fi;

	OIFS="${IFS}";
	IFS="${IFS}:";
    path=$(echo $1); shift;
	IFS="${OIFS}";
    item="$1";

    for d in ${path}; do {
	# echo searching $d for $item${suf:+ or $item$suf}... >&2;
	if [ -r $d/$item${suf:+${suf}} ]; then {
	    rs=$d/$item${suf:+${suf}};
	}
	elif [ -r $d/$item ]; then {
	    rs=$d/$item;
	} fi;
	if [ "$rs" ]; then {
	    echo "$rs" | sed 's,^\./,,';
	    return 0;
	} fi;
    } done;

    return 1;
}
#######

# I could get fancy with addpath... but why?

if [ -n "${DCOLOR_PATH}" ]; then {
    for d in $(echo ${DCOLOR_PATH} | tr : ' '); do {
	if [ -d ${d} ]; then {
	    MAPPATH=${MAPPATH}:$d;
	} fi;
    } done;
    MAPPATH=$(echo ${MAPPATH} | sed 's/^://');
} fi;

for freedom
do {
    case $1 in
    -d)
	shift;
	delay=$1;
	shift;
	;;
    -k)
	shift;
	if [ -f ${LOCK} ]; then {
	    read p t < ${LOCK};
	    kill $p > /dev/null 2>&1;
	} fi;
	xp reset;
	{ [ "$2" ] && { xc $1; xp -o $2; }; } ||
	{ [ "$1" ] && xtheme -o $1; }

	rm -f ${LOCK};
	exit;
	;;
    -l)
	shift;
	printf "Available maps:\n";
	for dir in $(echo ${MAPPATH} | tr : ' '); do {
	    cd $dir && {
		l=$(ls *.dcm 2> /dev/null | sed 's/.dcm//');
		printf "%15s " $l;
	    }
	    echo;
	} done;
	exit;
	;;
    -r)
	: restart with chosen theme;
        shift;
        ${PROG} -k;
	exec ${PROG} $1;
	;;
    -R)
	: restart with current theme;
	RELOAD=true;
    esac;
} done;

if [ -f ${LOCK} ]; then {
    read p t curtheme < ${LOCK};
    if kill -0 $p 2>/dev/null; then {
	if ${RELOAD:=false}; then {
	    ${PROG} -k;
	    exec ${PROG} ${curtheme};
	} fi;

	{
	    echo "dynamic color daemon $p already running on $t;" \
		"use ${PROG} -k to stop it."
	    exit 1;
	} ||
	{
	    echo "$p on $t dead; removing pid file...";
	    rm -f ${LOCK};
	}
    } fi;
} fi;

black=0 red=1 green=2 brown=3 blue=4 violet=5 turquoise=6 grey=7
coal=8 orange=9 lime=10 yellow=11 sky=12 magenta=13 cyan=14 white=15
: aliases
purple=5 turq=6 slate=7 ltgrey=7 dkgrey=8 ltblack=8
brightred=9 brightgreen=10 gold=11 brightblue=12 brightpurple=13
: attributes
bold=16 # dim=18 italic=19 uline=20 blink=21 inverse=23 hidden=24 ovs=25
: everything.
default=26 cursor=27 screen=28
# and aliases
bg=28 background=28

MAPNAME=$1;
DEFMAP=${HOME}/.dcolor.dcm;

case "${MAPNAME}" in
*/*.dcm)
	MAPFILE=${MAPNAME};
	;;
*/*)
	MAPFILE=${MAPNAME}.dcm;
	;;
"")
	MAPFILE=${DEFMAP};
	;;
*)
	MAPFILE=$(search -x .dcm ${MAPPATH} ${MAPNAME});
	;;
esac

if [ ! -f "${MAPFILE}" -o ! -r "${MAPFILE}" ] ; then {
    echo "Cannot find ${MAPNAME}";
    exit 1;
} fi;

MAP=$(grep -v '^#' ${MAPFILE} | tr ' ' '\n' |
	 sed -nre '/^[A-Za-z]+=/s//$&/p' -e '/^[0-9]?=/p');
#echo "MAP=${MAP:? failure}";
(
	trap 'rm -f $HOME/.pid.pmap; xp reset' 1 2 3 15;
	palmap $(eval echo ${MAP} ${delay:+DELAY=$delay}) &
	echo $! ${TTY} ${MAPNAME} > ${LOCK};
)
