#!/usr/bin/perl

#twfmanip

use strict;
use Text::CSV;

my $user = getlogin();
my $pid = $$;
my $tmp = "/tmp/$user-twfmanip-$pid";
my $diedie = "Invalid input! Example format:\ntwfmanip twffile.twf manipmode manipfile.csv\nmanipmode takes on the forms of P-t_VP, E-Vp, E-t_VP, CE-Vp, CE-t_VP, dI/dt-t_VP, and dV/dt-t_VP, where \"VP\" refers to the specific voltage pulse to use for those manipulation algorithms.\n";
#Input validation
if(@ARGV != 3) {
	die $diedie; #DIEDIEDIE!!!1
}

my $pwd;
if($ARGV[0] =~ /\//) {
	$pwd = $ARGV[0];
	$pwd =~ s/(.*)\/[^\/]*$/\1/;
} else {
	$pwd = `pwd`;
	$pwd =~ s/\n//g;
}
my $nwd; my $outfile;
if($ARGV[2] =~ /\//) {
	$nwd = $ARGV[2]; $outfile = $ARGV[2];
	$nwd =~ s/(.*)\/[^\/]*$/\1/;
	$outfile =~ s/.*\/([^\/]*)$/\1/;
} else {
	$nwd = $pwd;
	$outfile = $ARGV[2];
}

my $infile = $ARGV[0];
my $manipmode = $ARGV[1];

mkdir("$tmp");
system "cp \"$pwd/$infile\" $tmp";
system "cd $tmp; twf2csv \"$infile\"";
my $csvfile = $infile . ".csv";

my $csv = Text::CSV->new();

open(CSV, "$tmp/$csvfile") or die "Could not generate the temporary csv file! $!";

my $firstline = 1;
my @columnheaders;
my %data;
my $yheader;
my $xheader;
my @ydata;
my @xdata;

while(<CSV>) {
	if($csv->parse($_)) {
		my @columns = $csv->fields();
		if($firstline == 1) {
			$firstline = 0;
			@columnheaders = @columns;
		} else {
			for(my $i = 0; $i < @columns; $i++) {
				push(@{$data{$columnheaders[$i]}},@columns[$i]);
			}
		}
	} else {
		my $err = $csv->error_input;
		print "Failed to parse line: $err\n";
	}
}
close(CSV);

if($manipmode =~ /^P-t/) {
	$yheader = "P";
	$xheader = "t";
	my $vpulse = $manipmode;
	$vpulse =~ s/P-t_//g;
	my @vcol = @{$data{"V" . $vpulse}};
	my @icol = @{$data{"I" . $vpulse}};
	@xdata = @{$data{"timeV"}};
	for(my $i = 0; $i < @vcol; $i++) {
		push(@ydata,$vcol[$i]*$icol[$i]);
	}
} elsif($manipmode =~ /^E-Vp/) {
	$yheader = "E";
	$xheader = "Vp";
	my @tcol = @{$data{"timeV"}};
	my $deltaT = $tcol[1] - $tcol[0];
	for(my $i = 0; $i < (@columnheaders - 2) / 2; $i++) {
		my @vcol = @{$data{$columnheaders[2+$i]}};
		my @icol = @{$data{$columnheaders[2+$i+((@columnheaders - 2)/2)]}};
		my $vpulse = $columnheaders[2+$i];
		$vpulse =~ s/V//g;
		push(@xdata, $vpulse+0);
		my $energy = 0;
		for(my $j = 0; $j < @tcol; $j++) {
			$energy += $vcol[$j]*$icol[$j]*$deltaT;
		}
		push(@ydata, $energy);
	}
} elsif($manipmode =~ /^CE-Vp/) {
	$yheader = "CE";
	$xheader = "Vp";
	my @tcol = @{$data{"timeV"}};
	my $deltaT = $tcol[1] - $tcol[0];
	my $energy = 0;
	for(my $i = 0; $i < (@columnheaders - 2) / 2; $i++) {
		my @vcol = @{$data{$columnheaders[2+$i]}};
		my @icol = @{$data{$columnheaders[2+$i+((@columnheaders - 2)/2)]}};
		my $vpulse = $columnheaders[2+$i];
		$vpulse =~ s/V//g;
		push(@xdata, $vpulse+0);
		for(my $j = 0; $j < @tcol; $j++) {
			$energy += $vcol[$j]*$icol[$j]*$deltaT;
		}
		push(@ydata, $energy);
	}
} elsif($manipmode =~ /^E-t/) {
	$yheader = "E";
	$xheader = "t";
	@xdata = @{$data{"timeV"}};
	my $deltaT = $xdata[1] - $xdata[0];
	my $vpulse = $manipmode;
	$vpulse =~ s/E-t_//;
	my @vcol = @{$data{"V" . $vpulse}};
	my @icol = @{$data{"I" . $vpulse}};
	for(my $i = 0; $i < @vcol; $i++) {
		push(@ydata,$vcol[$i]*$icol[$i]*$deltaT);
	}
} elsif($manipmode =~ /^CE-t/) {
	$yheader = "CE";
	$xheader = "t";
	@xdata = @{$data{"timeV"}};
	my $deltaT = $xdata[1] - $xdata[0];
	my $vpulse = $manipmode;
	$vpulse =~ s/CE-t_//;
	my @vcol = @{$data{"V" . $vpulse}};
	my @icol = @{$data{"I" . $vpulse}};
	my $energy = 0;
	for(my $i = 0; $i < @vcol; $i++) {
		$energy += $vcol[$i]*$icol[$i]*$deltaT;
		push(@ydata, $energy);
	}
} elsif($manipmode =~ /^d.\/dt-t/) {
	$yheader = $manipmode;
	$yheader =~ s/(d.\/dt).*/\1/;
	$xheader = "t";
	@xdata = @{$data{"timeV"}};
	pop(@xdata);
	shift(@xdata); #What is this, a rap song?
	my $deltaT = $xdata[1] - $xdata[0];
	my $vpulse = $manipmode;
	$vpulse =~ s/d.\/dt-t_//;
	my $type = $manipmode;
	$type =~ s/d(.)\/.*/\1/;
	my @col;
	if($type =~ /[Ii]/) {
		@col = @{$data{"I" . $vpulse}};
	} else {
		@col = @{$data{"V" . $vpulse}};
	}
	for(my $i = 1; $i < @col - 1; $i++) {
		push(@ydata,(@col[$i+1] - @col[$i-1])/(2*$deltaT));
	}
} else {
	die $diedie;
}

open(OUTFILE, ">$nwd/$outfile") or die "Cannot create CSV file: $!";

print OUTFILE "$xheader,$yheader\n";

for(my $i = 0; $i < @xdata; $i++) {
	my $xval = $xdata[$i];
	my $yval = $ydata[$i];
	print OUTFILE "$xval,$yval\n";
}

close(OUTFILE);

system("rm -rf $tmp");
