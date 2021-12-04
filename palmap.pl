#@PERL@
#
# 
# TODO: allow %value on rhs to be a constant colour which is issued ONCE.
# @dsc:	Xterm palette colormap rotation program
####################
#
# palmap: palette-based colormap rotation.

use Time::HiRes qw(usleep nanosleep);

my(@pmap);	# palette maps, each an array of strings.
my(@indx,@ix);	# palette map indices.
my($o);		# offset
my($a, $b, $c, $x);	# temporary scalars.
my($mod, $off);	# modifier string, offset
my(@v);		# temporary array.
my($intv);	# sleep interval
my($outstr);	# output string
my($VERSION)	= 'palmap 4.0 2021-05-13 greywolf@starwolf.com';

# Where to find colourmap files
$CMAPS = $ENV{CMAP_DIR}? $ENV{CMAP_DIR}: "@LIBDIR@/cmap";

# magic sequence: \e]4;${palindx};#rrggbb [taken from maps in map file]
$PSET = "\e]4;%d;#%s\a";	# color palette set [0-15]
$ASET = "\e]5;%d;#%s\a";	# attribute set [16-25] -> [0-9]
$DSET = "\e]10;#%s\a";	# default color set [26]
$CSET = "\e]12;#%s\a";	# cursor color [27]
$BSET = "\e]11;#%s\a";	# background color set [28]


# delay between iterations
$DELAY = $intv = 366;

# 0: just list.

if ($ARGV[0] eq '-l') {
    foreach $x (${CMAPS}) {
	exec("/bin/ls -C $x | sed 's/\.cm/   /g'");
    }
}

# 1: determine palette-index:mapstring mappings.

foreach $a (@ARGV) {
    if ($a =~ /^([^:=]+)[:=](.*)/) {
	$v[$1]=$2;
    }
}

# 2: map arrays of strings
$b=0;
foreach $x (0..28) {
    if (defined($v[$x])) {
	if (open (thing, $CMAPS . "/" . $v[$x] . ".cm")) {
	    push @ix, $x;
	    # printf "pos=%s map=%s\n", $x, $v[$x];
	    while ($c = <thing>) {
		chomp($c);
		if ($c =~ /^[0-9a-f]{6}$/) {
		    push @{ $pmap[$x] }, $c;
		}
	    }
	    close (thing);
	    $indx[$x] = 0;

	++$b;
	}
	else {
	    die "${CMAPS}: $!";
	}
    }
}

select STDERR;
$| = 1;

#$intv /= $b;

while (1) {
    $outstr=undef;
    foreach $x (@ix) {
	if ($x < 16) {
	    $mod = $PSET;
	    $off = $x;
	    $outstr .= sprintf $mod, $off, $pmap[$x][$indx[$x]];
	}
	elsif ($x < 26) {
	    $mod = $ASET;
	    $off = ($x - 16);
	    $outstr .= sprintf $mod, $off, $pmap[$x][$indx[$x]];
	}
	else {
	    if ($x == 26) {
		$mod = $DSET;
	    }
	    elsif ($x == 27) {
		$mod = $CSET;
	    }
	    elsif ($x == 28) {
		$mod = $BSET;
	    }
	    $outstr .= sprintf $mod, $pmap[$x][$indx[$x]];
	}   
	if ( ++$indx[$x] > $#{$pmap[$x]} ) { $indx[$x] = 0; }
    }
    print STDERR $outstr;
    usleep($intv * 100);
}
# vim:	:sw=4:ts=8:ai:noet:
