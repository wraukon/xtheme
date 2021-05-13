#! /bin/sh -
# installer for the xtheme suite:

quit() { echo ; exit 1; }

PROGS="dcm.sh palmap.pl xc.sh xp.pl xtc.sh xtheme.sh fxdemo.sh"
DATAFILES="xthemes xtcolors xpalette";
DATADIRS="cmap dmap";
INSVER="installer 4.0 2021-05-13 greywolf@starwolf.com";
. ./VERSION;
DFL_DIR="/usr/local";

echo "Checking out a few things..."
BASH=$(type bash 2>/dev/null | awk '{print $NF}');
PERL=$(type perl 2>/dev/null | awk '{print $NF}');
INSTALL=$(type install 2>/dev/null | awk '{print $NF}');
RSYNC=$(type rsync 2>/dev/null | awk '{print $NF}');

if [ -z "${BASH}" ]; then {
    echo "I can't seem to find bash in your path;";
    read -p "Where should I look for it? " p || quit;
    for f in "${p}" "${p}/bash"; do {
	if [ -x "$f" ] && [ -f "$f" ]; then {
	    BASH="$f";
	} fi;
    } done;
} fi;

BASH=${BASH} ${BASH} -c 'echo bash is ${BASH}' || {
    echo "I'm sorry, this is no good.  Please install bash.";
    exit 1;
}

if [ -z "${PERL}" ]; then {
    echo "I beg pardon, but perl seem absent.";
    read -p "Whither perl? " p || quit;
    for f in "${p}" "${p}/perl"; do {
	if [ -x "$f" ] && [ -f "$f" ]; then {
	    PERL="$f";
	} fi;
    } done;
} fi;

PERL=${PERL} ${PERL} -e 'printf "perl is %s\n", $ENV{"PERL"};' || {
    echo "This just isn't working out.  Please install perl.";
    exit 1;
}

# silently set our copy routine

if [ -n "${RSYNC}" ]; then {
    COPY="rsync -Hrpmt --info=name";
}
else {
    COPY="cp -vf";
} fi;

verb="install";
verbing="${verb}ing";
direction="to";
where="whither";

while getopts :urayd: x; do {
    case $x in
    u)
	if update_check; then {
	    update_only=1;
	    verb="update";
	    verbing="updating";
	} fi;
	;;
    r)
	remove=1;
	verb="remove";
	verbing="removing";
	where="whence";
	direction="from";
	;;
    a|y)
	auto=1;	# do not ask any questions
	;;
    d)
	place=$(eval echo ${OPTARG});
	;;
    ?)
	echo "Bad option; exiting.";
	exit;
	;;
    esac;
} done;

shift $((OPTIND - 1));

if [ $(( update_only + remove )) -gt 1 ]; then {
    echo "Can't specify update and remove.";
    exit 1;
} fi;

if [ $# -gt 0 ]; then {
    place=$(eval echo $1);
} fi;

#: ${place:=${DFL_DIR}};

sed -e "s|@where|${where}|g" \
    -e "s|@verb|${verb}|g" \
    -e "s|@direction|${direction}|g" \
    -e "s|@VER|${VER}|g" \
    -e "s|@default|${DFL_DIR}|g" <<- '-EOT-'

### @VER ###

Preparing to @verb xtheme...

Everything looks good to go.

(If prompted, please provide the top level of a hierarchy @where
to @verb xtheme (/opt, /usr/local, and the like).
'${HOME}' is a permissible entry.)

Executables live in '@default/bin' by default.
Datafiles live in '@default/lib/xtheme/' by default.

If you press enter where a default is indicated, you are choosing the default.
If you press Ctrl+D (^D) at a prompt, the program will exit.

-EOT-

until [ ${install_ok=0} -eq 1 ]; do {
    if [ -n "${place}" ]; then {
	printf "%s %s %s\n" ${verbing} ${direction} ${place};
    }
    else {
	read -p "Install topdir [${DFL_DIR}]: " place || exit;
	place=$(eval echo ${place:-${DFL_DIR}});
    } fi;

    if [ $((auto)) -gt 0 ]; then {
	bin=${place}/bin;
	lib=${place}/lib/xtheme;
	for v in bin lib; do {
	    printf "%s : %s/%s\n" ${v} ${place} $(echo ${v});
	} done;
    }
    else {
	read -p "bin = [${place}/bin] " bin || quit;
	read -p "lib = [${place}/lib/xtheme] " lib || quit;
    } fi;
    mkdir -p ${bin:=${place}/bin} &&
	touch ${bin}/.$$foo &&    
	rm -f ${bin}/.$$foo &&
	mkdir -p ${lib:=${place}/lib/xtheme} &&
	install_ok=1 ||
	{
	    echo "Having problems writing to ${bin} or ${lib}";
            place=;
	    if ((auto)); then {
		echo "Automagic install requested; cannot continue.";
		exit 1;
	    } fi;
	}
} done;

echo;

if [ $((remove)) -gt 0 ]; then {
    cd ${place} || {
	echo "xtheme not installed at ${place}";
	exit;
    }
    printf "** Uninstalling xtheme:\n";
    (cd ${lib};
     rm -rvf ${DATADIRS}
     rm -vf ${DATAFILES};
    )
    (cd ${bin};
     for i in ${PROGS}; do {
	p=$(expr $i : '\(.*\)\..*');
	rm -vf $p;
     } done;
    )
    echo;
    exit;
} fi;

set -e;
if [ $((update_only)) -gt 0 ]; then {
    if [ ! -x ${bin}/xtheme ]; then {
	echo "Update requested, but no installation found in ${place}";
	echo "Running full install";
	update_only=0;
    } fi;
} fi;

printf "** %s xtheme:\n" ${verbing};
if [ $((update_only)) -eq 0 ]; then {
    printf "## installing programs:\n";
    for i in ${PROGS}; do {
	p=$(expr $i : '\(.*\)\..*');
	rm -vf ${bin}/$p;
	sed -e "s|@BINDIR@|${bin}|" \
	    -e  "s|@LIBDIR@|${lib}|" \
	    -e  "s|@BASH@|! ${BASH}|" \
	    -e  "s|@PERL@|! ${PERL}|" \
	    $i > ${bin}/$p;
	    chmod a+rx ${bin}/$p;
	    echo "$p -> ${bin}/$p";
    } done || xv=$(expr ${xv=0} + 1);
} fi;

printf "## %s data files:\n" ${verbing};
for i in ${DATAFILES}; do {
    ${COPY} $i ${lib}/$i;
} done || xv=$(expr ${xv=0} + 1);

for i in ${DATADIRS}; do {
    ${COPY} $i ${lib}/
} done || xv=$(expr ${xv=0} + 1);

if [ ${xv=0} -gt 0 ]; then {
    echo "Looks like you had some problems."
    echo "Fix the issues and try again.";
    exit ${xv};
} fi;

chmod -R a+rX ${lib}/;

printf "You can find updates for this program at\n\n%s\n" "${URL}";
