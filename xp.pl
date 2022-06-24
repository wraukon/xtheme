#@PERL@
# @xp:	palette rewrite
####################
# xp: palette rewrite.

use strict;

my($ac, @av) = ($#ARGV, @ARGV);

my($outstr);	# final output string
my($HOME) = $ENV{'HOME'};
my(@xppath) = (
	       ".xpalette",
	       ${HOME}."/.xpalette",
	       "@LIBDIR@/xpalette",
	      );
my($ix, $nv, $fn, $line, $mapping, $remap, $iterate, $colorall, $greyscale);
# light-text-to-grey array, dark-text-to-grey array, brightness index
my(@lt2grey, @dt2grey, @gsa, $bx);
my($dolist) = (0);
my($a, @b);
my(@clist);

my($CSI, $OSC) = ( "\e[", "\e]" );

my($VERSION) = 'xp 4.0.1 2022-01-25 greywolf@starwolf.com';

@lt2grey = (0x00, 0x6b, 0xb5, 0x89, 0x3f, 0x4e, 0x5c, 0xc4,
	    0x30, 0xd3, 0x98, 0xe1, 0x7a, 0xa6, 0xf0, 0xff);

@dt2grey = (0xff, 0xf0, 0xa6, 0x7a, 0x31, 0x98, 0xd3, 0x30,
	    0xc4, 0x5c, 0x4e, 0x3f, 0x89, 0xb5, 0x6b, 0x00);

sub osc {   #
    $outstr .= $_[0]? (${OSC} . "$_[0];") : "\a";
}

sub cset { # remap colour/attr (index,newval)
    ($ix,$nv) = @_;
    $outstr .= sprintf (";%d;%s", $ix, $nv? $nv: "?");
    ($iterate) && osc 0;
}

sub max {   # (ary)
    my($i, $max);

    foreach $i (@_) {
	if ($i > $max) { $max = $i; }
    }

    return $max;
}

sub min {   # (ary)
    my($i, $min);

    $min = 0xffffffff;

    foreach $i (@_) {
	if ($i < $min) { $min = $i; }
    }
    return $min;
}

sub getbx { # (peak, colour string)
	    # get brightness index:  Test each byte in the sequence, return
	    # peak (if > 0), valley (if 0)
	    # expects: 
    my($peak, $cstr) = @_;
    my($r, $g, $b);
   
    if ($cstr =~ m|#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})|) { 
	$r = $1; $g = $2; $b = $3; 
    }

    if ($peak) {
	return max(($r,$g,$b));
    }
    else {
	return min(($r,$g,$b));
    }
}

sub c2gs {  # colour to greyscale (really 'greydiant')
    my($cstr) = $_[0];
    my($x);	    # index
    my(@c);	    # c[0]: new r, c[1]: new g, c[2]: new b
    my($r, $g, $b);
    my(@gsr);    # greyscale returned
    # for now only doing light-text-to-grey

    # split out rgb
    if ($cstr =~ m,#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2}),) {
	$r=$1; $g=$2; $b=$3;
    }

    foreach $x (0..15) {
	$c[0] = $r * $lt2grey[$x];
	$c[1] = $g * $lt2grey[$x];
	$c[2] = $b * $lt2grey[$x];
	$gsr[$x] = sprintf("#%02x%02x%02x", $c[0], $c[1], $c[2]);
    }
    return @gsr;
}
#################


if ($av[0] eq "reset") {
    printf "${OSC}R";
    exit 0;
}

if ($av[0] eq "dump") {
    printf STDERR "Not implemented yet\n";
    exit 1;
}

while ($av[0] =~ /^-./) {
    if ($av[0] eq "-m") {
	$iterate = 1;
    }
    elsif ($av[0] eq "-l") {
	$dolist = 1;
    }
    elsif ($av[0] eq "-c") {
	$colorall = 1;
    }
    elsif ($av[0] eq "-g") {
	$greyscale = 1;
    }
    shift @av;
}

if ($dolist) {
    foreach $fn (@xppath) {
	if (open(fd, "<$fn")) {
	    while ($line = <fd>) {
		chomp($line);
		if ($line =~ /^[^#]\w+/) {
		    ($a,@b) = split(/\s+/,$line);
		    push @clist, $a;
		}
	    }
	}
    }
    #/* needs modification to work from tty size like xtheme does. */
    $ix=0;
    foreach $a (sort @clist) {
	++$ix;
	if ($a !~ /^\s+$/) {
	    printf "%-15s\t", $a;
	}
	if (! ($ix%5)) {
	    printf "\n";
	}
    }
    if ($ix %5) {
	printf "\n";
    }
    exit;
}
	    

if ($av[0] =~ /\S+/) {
    if ($colorall || $greyscale) {
	# please note that 'all' does not include
	# the special attributes.
	$a = $av[0];

	if ($colorall) {
	    for ($ix = 0; $ix < 16; $ix++) {
		if ($iterate || ($ix == 0)) {
		    osc 4;
		}
		cset($ix, $a);
	    }
	}
	if ($greyscale) {
	    # this is tricky.  If we have a light initial colour, we have to
	    # darken everything; if we have a dark initial colour, we have to
	    # lighten everything.
	    # if the initial colour has a valley of #66 or less, we lighten.
	    @gsa = c2gs($a);
	    for ($ix = 0; $ix < 16; $ix++) {
		cset($ix, $gsa[$ix]);
	    }
	}
	($outstr =~ m,\a$,) || osc 0;
	$outstr =~ s,;;,;,g;
	$outstr .= "\e]10;" . $a;
	osc 0;
	print $outstr;
	close(STDOUT);
	exit;
    }
    $remap = $av[0];
    $ix = 0;
    foreach $fn (@xppath) {
        if (open(fd, "<$fn")) {
	    $mapping = 0;
	    while ($line = <fd>) {
		chomp($line);
		if ($line =~ /^$remap/) {
		    $mapping = 1;   # mapping
		}
		elsif ($line =~ /^\s+/) {
		    $mapping = $mapping? 2: 0;   # continuing
		}
		elsif ($line =~ /^\S+/) {
		    $mapping = $mapping? 4: 0;   # mapping finished.
		}
		if ($mapping & 3) {
		    ($a, @b) = split(/\s+/, $line);
		    push @clist, @b;
		}
	        else {
		    if ($mapping) {
		        close(fd);

			for ($a = 0; $a < 16; $a++) {
			    if ($iterate || ($a == 0)) {
				osc 4;
			    }
			    cset($a, $clist[$a]);
			}
		
			($outstr =~ m,\a$,) || osc 0;
			
			for ($a = 0; $a < 5; $a++) {
			    if ($iterate || ($a == 0)) {
				osc 5;
			    }
			    cset($a, $clist[$a + 16]);
			}
			
			($outstr =~ m,\a$,) || osc 0;

			$outstr =~ s,;;,;,g;
			print $outstr;
			close(STDOUT);
			exit;
		    }
		}
	    }
	}
    }
    printf("%s: no such palette\n", $remap);
}

# vim:	:sw=4:ts=8:ai:noet:

