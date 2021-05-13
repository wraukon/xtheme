#@BASH@
############

MAP=fxdemo-1

colors=(BLACK RED GREEN BROWN BLUE PURPLE TURQ GREY \
	COAL ORANGE LIME GOLD SKY MAGENTA CYAN WHITE);

getss() {
    ss=($(stty size));
    nl=${ss[0]};
    nc=${ss[1]};
    (( cl = nl/2 ));
    (( cc = nc/2 ));
    tput clear;
}

getmap() {
    eval $(grep '^[^#].*=' @LIBDIR@/dmap/${MAP}.dcm | tr a-z A-Z);
}

status() {
    tput home el1 el
    printf "\e[0mc: %s fx: %s ci: %d cx: %d hi: %d" $c $fx $ci $cx $hi;
}

trap 'dcm -k default; tput clear' 0;
trap 'getss' WINCH;


getmap ${MAP};
getss;
ci=0;
hi=0;

tput clear;

dcm ${MAP} || exit;

for c in ${colors[*]}; do {

    if ((ci >= 010)); then {
	((ci -= 010));
	hi=1;
    } fi;

    fx=${!c} cx=$(printf "%o" $((030 + ci)) );

    ((cp = cc - (${#fx}/2) ));

    ((DEBUG)) && status;
    tput cup $cl $cp

    printf '\e[%d;%dm%s' $hi $cx $fx;
    sleep 5;
    ((++ci))
    ((++cl))
} done;

tput cup $nl 1
read -p "done: " r;

echo;
