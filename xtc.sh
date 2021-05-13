#! /bin/sh -
# @dsc:	xterm palette and attribute display
####################
:  test the colors of an Xterm

colorset="black red green yellow blue magenta cyan white"
colorset0="black red green brown blue purple turquoise lt_grey"
colorset1="dk_grey orange lime gold btblue rose cyan white"
bgset="black red green brown blue purple turquoise lt_grey"
attrib="normal bold dim italic uline blink unused inverse 
hidden overstrike"
attrib21="dbl-uline"
LABEL0="NORMAL"
LABEL1="HIGHLIGHT"
VERSION="xtc version 1.3 2015-07-14";

nl=0

if [ $1x = -ax ]; then {

    for attr in 0 1 2 3 4 5 6 7 8 9; do {
	eval set \$attrib;
	attroff=`expr $attr + 1`
	eval attrstr=\${$attroff}
	printf "\e[0;%dmAttr %d (%s)	" ${attr} ${attr} ${attrstr};
	[ $nl -ne 0 ] && echo;
	! (exit $nl);
	nl=$?;
    } done;
    printf "\e[0;21mAttr 21 (%s)" $attrib21;
    printf "\e[0m\n";
} fi;

printf "\n%-10s -> " "BASE COLOR";

for col in $(echo $colorset); do {
    printf "%s " "$col";
} done;
printf "\n\n";

for hilit in 0 1; do {
    set $(eval echo \$colorset$hilit);
    printf "%-10s :  " $(eval echo \$LABEL$hilit);
    for col in 0 1 2 3 4 5 6 7; do {
	printf "\e[$hilit;3${col}m%s\e[0m " "$1";
	shift;
    } done; 
    printf "\e[0m\n";
} done;

set $(echo $colorset0);
for col in 0 1 2 3 4 5 6 7; do {
    printf "\e[1;37;4${col}m%s bg\e[0m " "$1";
    shift;
} done;
printf "\e[0m\n";
# vim:	:sw=4:ts=8:ai:noet:
