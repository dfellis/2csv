#!/usr/bin/perl

#xls2csv3
#uses xls2csv to generate a "normal" (for csvplot) csv file

use strict;
use Text::CSV;

if(@ARGV != 1) {
        print "Syntax: xls2csv3 [XLSFILE]\n";
}

my $pid = $$;
my $user = getlogin();
my $tmp = "/tmp/$user-xls2csv3-$pid";
my $pwd = `pwd`;

system("mkdir $tmp; cp \"$ARGV[0]\" $tmp; xls2csv \"$tmp/$ARGV[0]\" > \"$tmp/$ARGV[0].csvish\"");

my @sheets;
my $index = 0;

open(CSVISH, "<$tmp/$ARGV[0].csvish");
open(CSV, ">$ARGV[0].csv");

my $csv = Text::CSV->new();
my $line = <CSVISH>;
print CSV $line;
$line = <CSVISH>;
while($line) {
	if($line =~ /^[0-9.e\-+",]+$/ && !($line =~ /^,+$/)) {
		print CSV $line;
	}
	$line = <CSVISH>;
}

close(CSVISH);
close(CSV);
