#!/usr/bin/perl

#TXT to CSV

my @titleArray;
my %dataArrays;
my $maxIndex = 0;
my $currIndex = 0;

my $outfile = $ARGV[0] . ".csv";

open(INFILE, "<", "$ARGV[0]") or die "Can't open \"$ARGV[0]\": $!";
open(OUTFILE, ">", "$outfile") or die "Can't create output file: $!";

while(<INFILE>) {
	$_ =~ s/ /,/g;
	if($_ =~ /^,*$/) {
		#Do nothing
	} elsif($_ =~ /^\@TIME\=,/) {
		#Do nothing
	} elsif($_ =~ /^,/) {
		#Do nothing
	} elsif($_ =~ /---/) {
		#Do nothing
	} else {
		my $out = $_;
		print OUTFILE $out;
	}
}

close(INFILE);

close(OUTFILE);
