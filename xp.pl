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
my($ix, $nv, $fn, $line, $mapping, $remap, $iterate, $colorall);
my($dolist) = (0);
my($a, @b);
my(@clist);

my($CSI, $OSC) = ( "\e[", "\e]" );

my($VERSION) = "xp version 3.0 2020-11-19-1555";

sub osc {   #
    $outstr .= $_[0]? (${OSC} . "$_[0];") : "\a";
}

sub cset { # remap colour/attr (index,newval)
    ($ix,$nv) = @_;
    $outstr .= sprintf (";%d;%s", $ix, $nv? $nv: "?");
    ($iterate) && osc 0;
}

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
    if ($colorall) {
	# please note that 'all' does not include
	# the special attributes.
	$a = $av[0];

	for ($ix = 0; $ix < 16; $ix++) {
	    if ($iterate || ($ix == 0)) {
		osc 4;
	    }
	    cset($ix, $a);
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

