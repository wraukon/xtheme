#! /bin/echo source-do-not-run

# cmap: attribute mapping
# cput: attribute display

declare -A cmap cput
CSI="\e[";
OSC="\e]";

# Notes:
#   set LIMIT1=1 if we are only capable of spitting out
#   one palette mapping at once.
#   This may not apply here; this may get relegated to
#   tcmap.pl

iterm2_init () {

    SQB="${OSC}1337;SetColors=";    # sequence basics
    SQP="${SQB}";		    # sequence palette
    SQA="${SQB}";		    # sequence attributes
    SQE='\a';			    # sequence end
    LIMIT1=1;	# limited to one change per call

    # "basics"
    cmap['fg']="fg=%s"; # chars
    cmap['bg']="bg=%s"; # screen
    cmap['curfg']="curfg=%s"; # cursor fg
    cmap['curbg']="curbg=%s"; # cursor bg

    # palette
    cmap['black']="black=%s";
    cmap['red']="red=%s";
    cmap['green']="green=%s";
    cmap['yellow']="yellow=%s";
    cmap['blue']="blue=%s";
    cmap['magenta']="magenta=%s";
    cmap['cyan']="cyan=%s";
    cmap['white']="white=%s";
    cmap['br_black']="br_black=%s";
    cmap['br_red']="br_red=%s";
    cmap['br_green']="br_green=%s";
    cmap['br_yellow']="br_yellow=%s";
    cmap['br_blue']="br_blue=%s";
    cmap['br_magenta']="br_magenta=%s";
    cmap['br_cyan']="br_cyan=%s";
    cmap['br_white']="br_white=%s";

    # additional attributes
    cmap['bold']="bold=%s";
    cmap['link']="link=%s";
    cmap['selfg']="selfg=%s";
    cmap['selbg']="selbg=%s";
    cmap['underline']="underline=%s";
    cmap['tab']="tab=%s";

}

xterm_init() {
    SQB="${OSC}";   # sequence basics
    SQP="${OSC}4;"  # sequence palette
    SQA="${OSC}5;"  # sequence attributes
    SQE='\a';	    # sequence end

    # "basics"
    cmap['fg']="10;%s";	# chars
    cmap['bg']="11;%s";	# screen
    cmap['curfg']="12;%s";    # cursor fg
    cmap['ptrfg']="13;%s";    # pointer fg
    cmap['ptrbg']="14;%s";    # pointer bg

    # palette
    cmap['black']="4;0;%s";
    cmap['red']="4;1;%s";
    cmap['green']="4;%s";
    cmap['yellow']="4;%s";
    cmap['blue']="4;%s";
    cmap['magenta']="4;%s";
    cmap['cyan']="4;%s";
    cmap['white']="4;%s";
    cmap['br_black']="4;%s";
    cmap['br_red']="4;%s";
    cmap['br_green']="4;%s";
    cmap['br_yellow']=";%s";
    cmap['br_blue']=";%s";
    cmap['br_magenta']=";%s";
    cmap['br_cyan']=";%s";
    cmap['br_white']=";%s";
}
