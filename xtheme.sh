#! /bin/sh -
#### xtheme: wrapper to set a full on xterm colour theme (std + palette)
VERSION="xtheme version 4.0.18 2020-11-23-2123";

THEMES="@LIBDIR@/xthemes";

dprintf() {
    local fmt;

    fmt=$1;

    ( exit $((diag)) ) && return ||
    shift;
    printf "${fmt}" ${1+"$@"} >&2;
}


gettheme() {
    local theme=$1 ext;
    awk '{
	ent=$1;
	if ($2 ~ /^@/) {
	    split($2,a,"@");
	    ref=a[2];
	    if (pal[ref] == "") {
		printf \
	"ERROR: %s, line %d: %s refers to (as yet) undefined palette %s\n",
		    FILENAME, FNR, theme, ref | "cat >&2";
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
	if (term[theme] == "") {
	    #printf "ERROR: cannot find theme %s\n", theme | "cat >&2";
	    exit 1;
	}
	printf "%s %s\n", term[theme], pal[theme];
	exit 0;
    }' theme=${theme} ${THEMES} ||
    exit 1;
}
#########################

if [ $# -lt 1 ]; then {
    echo "usage: xtheme theme";
    exit 2;
} fi;

ncol=$(stty size | awk '{print $2}');
term=$(tty);

while getopts :L:t:lomrd f; do {
    case $f in
    L)
	dolist=:;
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
    l)
	dolist=:;
	;;
    o|m)
    	oflag=-m;
	;;
    r)
	echo '[-r currently unimplemented; ignoring]';
	;;
    d)
	diag=1;
	;;
    esac;
} done;

shift $((OPTIND - 1));

theme=$1;
# have to do this here because getthem cannot control
# subshell (pipe-shell) variables.
{
    case ${theme} in
    # we might add -md|-mdark
    *-ml|*-mlight|*-m)
	ext=$(echo $theme | sed -re 's,.*(-[^-]*)$,\1,');
	theme=$(echo $theme | sed "s,${ext},,");
	dprintf 'converting theme %s to mono\n' "${theme}"
	xp_mono=1 export xp_mono;
	;;
    esac;
}

if ${dolist:=false}; then {
    if [ -n "${category}" ]; then {
	pat=$(echo ${category} | tr , '|');
    }
    else {
	pat="^[0-9a-z][-_0-9a-z]*";
    } fi;
    # this section is the output formatter
    # we have to grep | sort first to spit them
    # out in order.
    grep -Ee "${pat}" ${THEMES} |
    sort -u |
    awk 'BEGIN { pos=0; pnl=0; }
    {
	if (pnl) {
	    pnl=0; pos=0;
	    printf("\n");
	}
	pos+=16;
	printf "%-15s ", $1;
	if ((pos + 16) >= ncol) { pnl=1;}
    }
    END {
	if (pos) { printf "\n"; }
    }' ncol=${ncol}
    exit 0;
} fi;

gettheme $theme |
{
    read xc xp ||
    { 
	echo "no such xterm theme as $1." >&2;
	exit 2;
    }

    dprintf "theme=%s; xp_mono=%d\n" ${theme} ${xp_mono:=0};
    xcstr=$(xc $xc);

    if [ ${xp_mono} -ne 0 ]; then {
	xtfg=$(echo ${xcstr} |
	       tr '\033\007' @@ |
	       sed -re 's,.*@]10;([^@]*)@.*,\1,');
	mono="-c ${xtfg}";
    } fi;

    dprintf "mono: \n" "${mono}";
    dprintf "xcstr: %s\n" "${xcstr}" 2>&1 | cat -v;
    dprintf "xtfg: %s\n" "${xtfg}";
    dprintf "basic: %s\n" "${xc}";
    dprintf "palette: %s\n" "${xp}";

    printf "%s" ${xcstr};
    xp ${oflag} ${mono} $xp;	# now that xp is much faster, do it last.
} |
if [ -z "${tlist}" ]; then {
    cat;
}
else {
    tee ${tlist:-/dev/tty} > /dev/null;
} fi;

# vim:	:sw=4:ts=8:noet:ai:
