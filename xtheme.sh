#! /bin/sh -
#### xtheme: wrapper to set a full on xterm colour theme (std + palette)
VERSION="xtheme 5.3 greywolf@starwolf.com 2023-05-12 12:38 PDT";

THEMES="@LIBDIR@/xthemes";
MYCONFIG="${HOME}/.xtheme";

extern() {  # this doesn't work as well as I'd like in sh.
    true;   # so we'll just do this.
}

dprintf() {
    local fmt;

    fmt=$1;

    ( exit $((diag)) ) && return ||
    shift;
    printf "${fmt}" ${1+"$@"} >&2;
}

list_themes () {
    extern category;
    local single multi showcat pattern opt OPTIND _;

    OPTIND=1;

    while getopts :sCcp: opt; do {
	case ${opt} in
	c)
	    : $((++showcat));
	    ;;
	p)
	    pattern=${OPTARG};
	    ;;
	s)
	    single=1; multi=0;
	    ;;
	C)
	    multi=1; single=0;
	    ;;
	esac;
    } done;

    shift $((OPTIND-1));

# we are doing this in main; don't do it again here!
#    if [ ! -t 1 ] && [ $((multi)) -eq 0 ]; then {
#	single=1;
#    }
#    else {
#	multi=1;
#    } fi;

#    read -p "(list_themes) single=$single multi=$multi" _;

    if [ -n "${category}" ]; then {
	pattern=$(echo ${category} |
	    sed -e 's/\*/.*/g' -e 's/\?/./g' |
	    tr , '|');
    }
    else {
	pattern="^[0-9a-z][-_0-9a-z]*";
    } fi;
    # this section is the output formatter
    # we have to grep | sort first to spit them
    # out in order.
    grep -Ee "${pattern}" ${THEMES:?GAH.} |
    sort -u |
    awk -F'\t' 'BEGIN { pos=0; pnl=0; showcat=0; }
    {
	if (pnl) {
	    pnl=0; pos=0;
	    printf("\n");
	}
	if (showcat) {
	    printf("%-15s\t%s\n", $1, $NF);
	}
	else {
		pos+=16;
		printf("%-15s ", $1);
		if ((multi && ((pos + 16) >= ncol)) || !multi) { pnl=1;}
	}
    }
    END {
	if (pos) { printf "\n"; }
    }' ncol=${ncol} multi=$((multi)) showcat=$((showcat));
}

get_section() {
    local sec;
    sec=$1; shift;

    if [ -r ${MYCONFIG} ]; then {
	sed -Ene "/^\[$sec\]$/,/^$/p" ${MYCONFIG} |
	    sed -Ee "/^(\[.*\]|)$/d"
    } fi;
}

get_theme() {
    local _theme=$1 ext;
    awk '{
	ent=$1;
	if ($2 ~ /^@/) {
	    split($2,a,"@");
	    ref=a[2];
	    if (pal[ref] == "") {
		printf \
	"ERROR: %s, line %d: %s refers to (as yet) undefined palette %s\n",
		    FILENAME, FNR, theme, ref |"cat >&2";
		    exit 1;
	    }
	    else {
		term[ent]=term[ref];
		pal[ent]=pal[ref];
	    }
	}
	else {
	    term[ent]=$2;
	    pal[ent]=$3;
	}
    }
    END {
	if (term[_theme] == "") {
	    #printf "ERROR: cannot find theme %s\n", theme | "cat >&2";
	    exit 1;
	}
	printf "%s %s\n", term[_theme], pal[_theme];
	exit 0;
    }' _theme=${_theme} ${THEMES} ||
    exit 1;
}

get_random() {
    local _nt _t _tbuf;

    if [ ! -f ${MYCONFIG} ]; then {
	fmt -w 77 <<- EOT
	Creating list of themes for use with -r.  Feel free to edit
	the file.  If you remove it, it will be regenerated with
	a default list next time you run with -r.
	EOT
	{
		echo '[themes]';
		list_themes -s ;
	} > ${MYCONFIG};
    } fi >&2;

    if [ ! -r ${MYCONFIG} ]; then {
	echo "Cannot read ${MYCONFIG}";
	return;
    } fi >&2;

    _tbuf="$(sed -n '/\[themes\]/,/^$/p' ${MYCONFIG} |
	grep -Ev '\[themes\]|^$')";
    _nt=$(echo "${_tbuf}" | wc -l);
    : $((_t = (RANDOM % _nt) + 1));
    echo "${_tbuf}" | sed -n "${_t}p";
}

#########################

# XXX TODO:
# - option to list categories, as well as
#   theme/category pairs.
# - option to print usage/help

while getopts :dlmorvC1L:t: f; do {
    case $f in
    d)
	diag=1;
	;;
    l)
	dolist=1;
	;;
    o|m)
    	oflag=-m;
	;;
    r)
	pick_random=1;
	;;
    v)
	echo "${VERSION}";
	exit;;
    C)
	dolist=1;
	multi=1;    # a la ls(1);
	;;
    1)
	dolist=1;
	single=1;   # a la ls(1);
	;;
    L)
	dolist=1;
	category=${OPTARG};
	;;
    t)
	if [ -c /dev/${OPTARG} ]; then {
	    tlist+="/dev/${OPTARG}" ;
	}
	elif [ -c /dev/pty${OPTARG} ]; then {
	    tlist+="/dev/pty${OPTARG} ";
	}
	elif [ -c /dev/pty/${OPTARG} ]; then {
	    tlist+="/dev/pty/${OPTARG} ";
	}
	elif [[ ${OPTARG} == [p-w][0-f] && -c /dev/tty${OPTARG} ]]; then {
	    tlist+="/dev/tty${OPTARG} ";
	} fi;
	;;
    ?)
	echo "Unknown option: $f";
	exit 1;
	;;
    esac;
} done;

shift $((OPTIND - 1));

if [ $((dolist)) -gt 0 ]; then {
    if [ -t 1 ]; then {	# a la ls(1);
	ncol=$(stty size | awk '{print $2}');
	: $((multi = !single));
    }
    else {
	ncol=80;    # assume default
    } fi;

    : $((single = !multi));

#    read -p "single=$single multi=$multi" _ < /dev/tty

    if [ $((multi)) -gt 0 ]; then {
	list_themes -C ${1+-p "$1"};
    }
    elif [ $((single)) -gt 0 ]; then {
	list_themes -s ${1+-p "$1"};
    } fi;
    exit;
} fi;

if [ "$1" ]; then {
    theme=$1;
}
else {
    theme=$(get_section default);
    if [ "${theme}" = "random" ]; then {
	: $((++pick_random));
    } fi

    if [ $((pick_random)) -gt 0 ]; then {
	theme=$(get_random);
    } fi;
} fi;

if [ ! "${theme}" ]; then {
    echo "usage: xtheme theme";
    exit 1;
} fi;


if [ $((diag)) -gt 0 ]; then {
    while read -p "(dbx) " a; do {
	eval "$a";
    } done;
} fi;



if [ ! "${theme}" ]; then {
    echo "No theme found/requested.";
    exit 1;
} fi;

# have to do this here because get_theme cannot control
# subshell (pipe-shell) variables.
{
    case ${theme} in
    # we might add -md|-mdark
    *.ml|*.mlight|*.m)
	ext=$(echo $theme | sed -re 's,.*(\.[^.]*)$,\1,');
	theme=$(echo $theme | sed "s,${ext},,");
	dprintf 'converting theme %s to mono\n' "${theme}"
	xp_monogrey=1;
	;;
    *.md|*.mdark)
	echo ".md not yet implemented";
	exit 1;;
    *.g|*.gs|*.gr[ae]y|*.gr[ae]yscale)
	ext=$(echo $theme | sed -re 's,.*(\.[^.]*)$,\1,');
	theme=$(echo $theme | sed "s,${ext},,");
	dprintf 'converting theme %s to greyscale\n' "${theme}"
	xp_monogrey=3;
    esac;
}

get_theme $theme |
{
    read xc xp ||
    { 
	echo "no such xterm theme as $1." >&2;
	exit 2;
    }

    dprintf "theme=%s; xp_monogrey=%d\n" ${theme} ${xp_monogrey:=0};
    xcstr=$(xc $xc);

    xtfg=$(echo ${xcstr} |
	   tr '\033\007' @@ |
	   sed -re 's,.*@]10;([^@]*)@.*,\1,');

    case ${xp_monogrey} in
    1)
	mono="-c ${xtfg}";
	;;
    #2 is reserved for mono-dark
    3)
	grey="-g ${xtfg}";
	;;
    esac;

    dprintf "monogrey: \n" "${monogrey}";
    dprintf "xcstr: %s\n" "${xcstr}" 2>&1 | cat -v;
    dprintf "xtfg: %s\n" "${xtfg}";
    dprintf "basic: %s\n" "${xc}";
    dprintf "palette: %s\n" "${xp}";

    printf "%s" ${xcstr};
    xp ${oflag} ${monogrey} $xp; # now that xp is much faster, do it last.
} |
if [ -z "${tlist}" ]; then {
    cat;
}
else {
    tee ${tlist:-/dev/tty} > /dev/null;
} fi;

# vim:	:sw=4:ts=8:noet:ai:
