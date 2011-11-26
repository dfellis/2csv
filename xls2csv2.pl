#!/usr/bin/perl

#xls2csv2
#uses xls2csv to generate a "normal" (for csvplot) csv file

use strict;
use Text::CSV;

if(@ARGV != 1) {
	print "Syntax xls2csv2 [XLSFILE]\n";
}

my $pid = $$;
my $user = getlogin();
my $tmp = "/tmp/$user-xls2csv2-$pid";
my $pwd = `pwd`;

system("mkdir $tmp; cp $ARGV[0] $tmp; xls2csv $tmp/$ARGV[0] > $tmp/$ARGV[0].csvish");

my @sheets;
my $index = 0;

open(CSVISH, "<$tmp/$ARGV[0].csvish");

my $csv = Text::CSV->new();
my $line = <CSVISH>;
while($line) {
	while(!($line =~ /\f/)) {
		$csv->parse($line);
		my @columns = $csv->fields();
		push(@{$sheets[$index]}, \@columns);
		$line = <CSVISH>;
	}
	if($sheets[$index] eq undef) {
		$index--;
	}
	$index++;
	$line = <CSVISH>;
}

close(CSVISH);

my @widths;
my $length = 0;
for(my $i = 0; $i < @sheets; $i++) {
	for(my $j = 0; $j < @{$sheets[$i]}; $j++) {
		if($widths[$i] < @{${$sheets[$i]}[$j]}) {
			$widths[$i] = @{${$sheets[$i]}[$j]};
		}
	}
	if($length < @{$sheets[$i]}) {
		$length = @{$sheets[$i]};
	}
}

sub nCommas {
	my $num = shift;
	my $out = "";
	for(my $i = 0; $i < $num; $i++) {
		$out .= ",";
	}
	return $out;
}

open(CSV, ">$ARGV[0].csv");

for(my $i = 0; $i < $length; $i++) {
	for(my $j = 0; $j < @sheets; $j++) {
		if(${$sheets[$j]}[$i]) {
			print CSV join(",", @{${$sheets[$j]}[$i]});
			if(@{${$sheets[$j]}[$i]} < $widths[$i]) {
				print CSV nCommas($widths[$i] - @{${$sheets[$j]}[$i]});
			}
		} else {
			print CSV nCommas($widths[$j]);
		}
		if($j < (@sheets - 1)) {
			print CSV ",";
		}
	}
	print CSV "\n";
}

close(CSV);

system("rm -rf $tmp");