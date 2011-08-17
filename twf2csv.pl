#!/usr/bin/perl

#TWF to CSV

my @titleArray;
my %dataArrays;
my $maxIndex = 0;
my $currIndex = 0;
my $Vwidth = 0;
my $deltaTV;
my $deltaTI;
my %usedVPulses;
my %usedIPulses;

open(INFILE, "<", "$ARGV[0]") or die "Can't open \"$ARGV[0]\": $!";

my $mode = "null";
push(@titleArray, "timeV", "timeI");
while(<INFILE>) {
	if($_ =~ m/^\s*$/ && $mode eq "null") {
		$mode = "deltaTvoltage";
	} elsif($mode eq "deltaTvoltage") {
		$_ =~ m/([0-9]*\.[0-9]*[E+-]*[0-9]*)/;
		$deltaTV = $1;
		$deltaTV += 0;
		$mode = "pulseV";
	} elsif($mode eq "pulseV") {
		while($_ =~ m/([-]*[0-9]*\.[0-9]*[E+-]*[0-9]*)/) {
			my $tempV = $1;
			$tempV += 0;
			if(exists($usedVPulses{$tempV})) {
				$usedVPulses{$tempV}++;
				$tempV = $tempV . "-" . $usedVPulses{$tempV};
			} else {
				$usedVPulses{$tempV} = 0;
			}
			$tempV = "V" . $tempV . "V";
			push(@titleArray, $tempV);
			$_ =~ s/[-]*[0-9]*\.[0-9]*[E+-]*[0-9]*//;
			$Vwidth++;
		}
		$mode = "preVdata";
	} elsif($mode eq "preVdata") {
		$mode = "Vdata";
	} elsif($_ =~ m/[0-9]/ && $mode eq "Vdata") {
		my $tempT = $currIndex*$deltaTV;
		if(defined($dataArrays{$currIndex})) {
			push(@{$dataArrays{$currIndex}}, $tempT, $tempT); #Corrected Later
		} else {
			$maxIndex = $currIndex;
			$dataArrays{$currIndex} = [$tempT, $tempT];
		}
		while($_ =~ m/([-]*[0-9]*\.[0-9]*[E+-]*[0-9]*)/) {
			my $tempV = $1;
			push(@{$dataArrays{$currIndex}},$tempV);
			$_ =~ s/[-]*[0-9]*\.[0-9]*[E+-]*[0-9]*//;
		}
		$currIndex++;
	} elsif($_ =~ m/^\s*$/ && $mode eq "Vdata") {
		$mode = "deltaTcurrent";
	} elsif($mode eq "deltaTcurrent") {
		$_ =~ m/([0-9]*\.[0-9]*[E+-]*[0-9]*)/;
		$deltaTI = $1;
		$deltaTI += 0;
		$mode = "pulseI";
	} elsif($mode eq "pulseI") {
		while($_ =~ m/([-]*[0-9]*\.[0-9]*[E+-]*[0-9]*)/) {
			my $tempI = $1;
			$tempI += 0;
			if(exists($usedIPulses{$tempI})) {
				$usedIPulses{$tempI}++;
				$tempI = $tempI . "-" . $usedIPulses{$tempI};
			} else {
				$usedIPulses{$tempI} = 0;
			}
			$tempI = "I" . $tempI . "V";
			push(@titleArray, $tempI);
			$_ =~ s/[-]*[0-9]*\.[0-9]*[E+-]*[0-9]*//;
		}
		$mode = "preIdata";
	} elsif($mode eq "preIdata") {
		$mode = "Idata";
		$currIndex = 0;
	} elsif($_ =~ m/[0-9]/ && $mode eq "Idata") {
		my $tempT = $currIndex*$deltaTI;
		${$dataArrays{$currIndex}}[1] = $tempT; #Correction
		while($_ =~ m/([-]*[0-9]*\.[0-9]*[E+-]*[0-9]*)/) {
			my $tempI = $1;
			push(@{$dataArrays{$currIndex}},$tempI);
			$_ =~ s/[-]*[0-9]*\.[0-9]*[E+-]*[0-9]*//;
		}
		$currIndex++
	}
}

close INFILE;

my $outfile = $ARGV[0] . ".csv";

open(OUTFILE, ">", "$outfile") or die "Can't create output file: $!";

{
  local $, = ',';
  print OUTFILE @titleArray;
}
print OUTFILE "\n";

for(my $i = 0; $i <= $maxIndex; $i++) {
	{
		local $, = ',';
		print OUTFILE @{$dataArrays{$i}};
	}
	print OUTFILE "\n";
}

close(OUTFILE);
