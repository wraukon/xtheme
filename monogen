#! /bin/bash -
#
VER="1.0 2023-03-27 14:08 PDT greywolf@starwolf.com";
PROG=${0##*/};

usage() {
    local _xv;
    _xv=$1;

    exec >&2;
    echo "usage: $PROG color-tag white-value";
    echo "color-tag is the name you wish to give the map";
    echo "white-value is the full-on white value in rrggbb format,";
    echo "optionally preceded by 0x or #.";
    exit $((_xv));
}

# future option parser here

# /opts

if (($# != 2)); then {
    usage 1;
} fi;
	

cn="${1,,}";
bc="${2,,}";

if ! [[ $(echo "${bc}" | sed -E -n 's/^(#|0x)?([0-9a-f]{6})$/\2/p') ]]; then {
    exec >&2;
    echo "$bc: bad color string";
    echo "color string must be rrggbb optionally preceded by '#' or '0x'";
    exit 1;
} fi;

mx0=(00 6b b5 89 3f 4e 5c c4 30 d3 98 e1 7a a6 f0 ff);
mx1=(ff 30 5c 3f e1);

bc=${bc/0x/}; bc=${bc/#/};
br=${bc::2};
bg=${bc:2:2};
bb=${bc:4:2};

#echo "r $br g $bg b $bb";

printf "%s" ${cn};

for ((n=${#mx0[@]}, c=0; c < n; c++)); do {
#    echo "br $br bg $bg bb $bb c $c mx0[$c] ${mx0[$c]}";
    printf "\t#%02x%02x%02x" \
	$(( (0x$br * 0x${mx0[$c]}) / 0xff )) \
	$(( (0x$bg * 0x${mx0[$c]}) / 0xff )) \
	$(( (0x$bb * 0x${mx0[$c]}) / 0xff ));
    if (( ! ((c+1) % 8) )); then
	echo;
    fi;
} done;

for ((n=${#mx1[@]}, c=0; c < n; c++)); do {
#    echo "br $br bg $bg bb $bb c $c mx0[$c] ${mx0[$c]}";
    printf "\t#%02x%02x%02x" \
	$(( (0x$br * 0x${mx0[$c]}) / 0xff )) \
	$(( (0x$bg * 0x${mx0[$c]}) / 0xff )) \
	$(( (0x$bb * 0x${mx0[$c]}) / 0xff ));
} done;
echo;
