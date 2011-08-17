#!/usr/bin/perl

#TLP to CSV

my @titleArray;
my %dataArrays;
my $maxIndex = 0;
my $currIndex = 0;

open(INFILE, "<", "$ARGV[0]") or die "Can't open \"$ARGV[0]\": $!";

my $mode = "null";
while(<INFILE>) {
	if($_ =~ /Multi-Leakage/) {
		$mode = "titles";
	} else {
		if($mode eq "null") {
			#Do nothing
		} elsif($mode eq "titles") {
			my $out = $_;
			$out =~ s/[ \r\n\t]//g;
			$out =~ s/\)/),/g;
			$out =~ s/[()]//g;
			$out =~ s/Volts//g;
			$out =~ s/Amps//g;
			$out =~ s/SPLEAKAGE/LEAK/g;
			#$out =~ s/[\t]/,/g;
			$out =~ s/,$//g;
			push(@titleArray, $out);
			$mode = "data";
		} elsif($mode eq "data") {
			#$_ =~ /([0-9.eE+-]*)[ \t]*([0-9.eE+-]*)[ \t]*([0-9.eE+-]*)[ \t]*([0-9.eE+-]*)/;
			#my @data = [ $1, $2, $3, $4 ];
			$_ =~ s/[\t]/,/g;
			$_ =~ s/[ ]+/,/g;
			$_ =~ s/[\n]//g;
			if(defined($dataArrays{$currIndex})) {
				push(@{$dataArrays{$currIndex}}, $_);
				$currIndex++;
			} else {
				$maxIndex = $currIndex;
				$dataArrays{$currIndex} = [ $_ ];
				$currIndex++;
			}
		}
	}
}

close INFILE;

my $outfile = $ARGV[0];
#$outfile =~ s/tlp/csv/;
$outfile .= ".csv";

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
