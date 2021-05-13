#@BASH@
# @dsc:	aterm/xterm/rxvt colour scheme (text, cursor, pointer) changer
####################
#
# xc: set colours according to a colour scheme
#
#: usage:	xc [ -f colorfile ] { -[lr] [ -L ] | scheme }
#: options:	-l: list schemes
#: 		-f: specify an alternate colour file
#: 		-r: pick one at random
#:		-R tag{,tag...}:  pick one from the given tags
#: 		-v: print what we've picked
# DEPRECATED
#		-b { brightness | [low]:high | low:[high] }
#
# 3.3 - minor rev: bug in parsing. Solution: compress multiple tabs.
# 3.2.1 - bugfix: add default panic theme until I can get back to normal.
# 3.2 - minor rev:  adjusting flag values from true/false to 1/0.
#		    adjusting option parser to use getopts.
#		    Disabling -D, -L until I can re-interpret what
#		    they actually mean.  Might never happen.
# 3.1 - minor rev:  ran fixvars, fixed message for -R if no such category
#	exists.
# 3.0 - major rev
#	deprecating the -L/-D/-b tags
#	changing field 6 to "category"
####
# 2.1 - minor rev
#	$6 is now brightness from 0-5, and sense of light/dark is reversed
#	Adding options:
#		-b range	acceptable brightness range
#		-D only use "dark" [012] colours
#	Revising options:
#		-L only use "light" [345] colours
# 2.0 - major rewhack
#	file format changed: $6 = 'too dark for tinted transparency'
#	adding -r flag
#	properly parsing options
#####
DATAFILE="@LIBDIR@/xtcolors";
#OPTS="lrvR:b:f:";
OPTS="lrvR:f:";
# change these if we need better resolution than this.
#lMIN=0;
#lMAX=5;
VERSION="xc 4.0 2021-05-13 greywolf@starwolf.com";

# lower and upper midrange
#(( lMIDL = (lMAX + lMIN) / 2 ))
#(( lMIDU = (lMAX + lMIN + 1) / 2 ))

usage() {
    sed -nre '/^#: /s/&//p' $0 >&2
    exit 2;
}

unimp() {
    echo "This feature is not (yet?) implemented.";
    exit 2;
}

ttecho() {
    if (( $1 )); then {
	echo "$@" > /dev/tty;
    } fi;
}

panic_theme() {
    printf "\e]10;#808080\a";
    printf "\e]11;#000000\a";
    printf "\e]12;#ff0000\a";
    printf "\e]13;#00ff00\a";
    exit;
}

####
set -- $(getopt "${OPTS}" "$@");

while getopts :lrvDLR:f: x; do {
    case $x in
    l)
	lFLAG=1;
	;;
    D)
	unimp;
	range=${lMIN}:${lMIDL};
	;;
    L)
	unimp;
	range=${lMIDU}:${lMAX};
	;;
    r)
	rFLAG=1;
	;;
    v)
	vFLAG=1;
	;;
    f)
	case ${OPTARG} in
	/*)
	    DATAFILE=${OPTARG};
	    ;;
	*)
	    DATAFILE=${DATAHOME}/${OPTARG};
	    ;;
	esac;
	;;
    R)
	RFLAG=1;
	category=${OPTARG//,/|};
	;;
    ?)
	echo "Don't grok -$x";
	exit 2;	#NOTREACHED
	;;
    esac
} done;

shift $((OPTIND-1));

want=$1;

if [ "$want" = "panic" ]; then {
    panic_theme;
} fi;

DEBUG=${DEBUG+1};
####

if [ -t 0 ]; then {
    ttywidth=`stty size | awk '{print $2}'`
}
else {
    ttywidth=80
} fi;

### maybe once I figure this out again.
#eval $(echo ${range:-${lMIN}:${lMAX}} | \
#   	awk -F: '{printf "low=%d high=%d", $1, (NF>1)? $2: 0;}');

#(( high > lMAX )) && high=${lMAX};
#(( low < lMIN )) && low=${lMIN};
#(( high < low )) && high=${low};

#${vFLAG:+echo low/high} : ${low} / ${high}

if ((lFLAG=lFLAG)); then {  # will force lFLAG to 0 if it's not set
    awk '$1 !~ /#|^$/ {
	    if (($NF ~ category || category == "") &&
		    $NF !~ "ignore") {
		print $1;
	    }
	}' category="${category}" ${DATAFILE} |
    	sort |
	awk 'BEGIN {
		width=0;
	    }
	    {
		len=length($1);
		if (len > width) {
		    width=len;
		}
		el[NR]=$1;
	    }
	    END {
		width += 1;
		fmtstring=sprintf("%%-%ds", width);
		curpos=0;
		for (r=1; r <= NR; r++) {
			printf (fmtstring, el[r]);
			curpos += width;
			if ((curpos + width) > ttywidth) {
			    printf ("\n");
			    curpos=0;
			}
		}
	    }' ttywidth=${ttywidth};
    printf '\n'
    exit 0
} fi

if (( rFLAG || RFLAG )); then {
    nl=$(sed -nre 's/^#.*//' -e '/^[[:space:]]+$|^$/d' \
   		${rFLAG:+-e '/ignore/d'} -e p ${DATAFILE} | \
	awk '($NF ~ category || category == "")' category=${category} |
	tee /tmp/.xtco$$ | wc -l);
    if (( nl == 0 )); then {
	printf "no colour schemes in %s\n" "${category}";
	exit 0;
    } fi;
    (( nr = ( RANDOM % nl ) + 1));
    SCHEME=$(awk 'NR == want { \
		print $2, $3, $4, $5, $NF, $1, "random", NR, $6 ; \
	    }' want=${nr} /tmp/.xtco$$);
}
else {
    ttecho $((vFLAG || DEBUG)) looking for ${want};

    SCHEME=$(awk '$1 == scheme { \
			print $2, $3, $4, $5, $NF, $1, "file", NR, $6;\
		    }' scheme=${want} ${DATAFILE} );
} fi;

if [ ! "${SCHEME}" ]; then
    echo "No such xterm colour scheme as $1." >&2;
    if [ "${nr}" ]; then {
	echo "nr=${nr} nl=${nl}; check /tmp/.xtco$$";
    } fi;
    exit 1
fi

#set ${SCHEME}
s=(${SCHEME})
ttecho $((vFLAG || DEBUG)) file : ${DATAFILE}
ttecho $((vFLAG || DEBUG)) scheme : "${s[5]} (${s[4]}): ${s[6]} rec ${s[7]}";
if ((DEBUG)); then {
    printf "fg %s bg %s ptr %s csr %s\n" \
	"${s[0]}" "${s[1]}" "${s[2]}" "${s[3]}";
}
else {
    printf "\e]10;%s\a\e]11;%s\a" "${s[0]}" "${s[1]}";
    printf "\e]12;%s\a\e]13;%s\a" "${s[3]}" "${s[2]}";
    printf "\e]14;%s\a" "${s[1]}";
    printf "\e]1;%s\a" "${s[4]}";
} fi;
rm -f /tmp/.xtco$$;

