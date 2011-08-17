#!/usr/bin/perl

#PLT to CSV

my @titleArray;
my %dataArrays;
my $maxIndex = 0;
my $currIndex = 0;
my $maxColumn = 0;
my $currColumn = 0;
my $pltType = "null";

open(INFILE, "<", "$ARGV[0]") or die "Can't open \"$ARGV[0]\": $!";

my $mode = "null";
while(<INFILE>) {
	if($_ =~ /datasets/) {
		$pltType = "sim";
		$mode = "titles";
		my $out = $_;
		$out =~ s/datasets[\t \n]*= \[//g;
		$out =~ s/,/ /g;
		$out =~ s/" "/,/g;
		$out =~ s/"//g;
		$out =~ s/ +/ /g;
		$out =~ s/\n//g;
		$out =~ s/^ *//g;
		$out =~ s/ *$//g;
		push(@titleArray, split(/,/,$out));
	} elsif($_ =~ /\]/ && $mode eq "titles") {
		$pltType = "sim";
		$mode = "null";
		my $out = $_;
		$out =~ s/\]//g;
		$out =~ s/,/ /g;
		$out =~ s/" "/,/g;
		$out =~ s/"//g;
		$out =~ s/ +/ /g;
		$out =~ s/\n//g;
		$out =~ s/^ *//g;
		$out =~ s/ *$//g;
		push(@titleArray, split(/,/,$out));
		$maxColumn = @titleArray;
	} elsif($_ =~ /Data {/) {
		$pltType = "sim";
		$mode = "data";
	} elsif($_ =~ /.scan merge/) {
		$pltType = "dc";
		$mode = "null";
		$currIndex = 0;
	} elsif($_ =~ /.vars/) {
		$pltType = "dc";
		$mode = "titles";
	} elsif($_ =~ /.data/) {
		$pltType = "dc";
		$mode = "data";
	} else {
		if($mode eq "null" || $pltType eq "null") {
			#Do nothing
		} elsif($pltType eq "sim" && $mode eq "titles") {
			my $out = $_;
			$out =~ s/,/ /g;
			$out =~ s/" "/,/g;
			$out =~ s/"//g;
			$out =~ s/ +/ /g;
			$out =~ s/\n//g;
			$out =~ s/^ *//g;
			$out =~ s/ *$//g;
			push(@titleArray, split(/,/,$out));
		} elsif($pltType eq "sim" && $mode eq "data") {
			while($_ =~ m/[0-9.eE+-]+/) {
				$_ =~ s/([0-9.eE+-]+)//;
				if(defined($dataArrays{$currIndex})) {
					push(@{$dataArrays{$currIndex}}, $1);
					$currColumn++;
					if($currColumn >= $maxColumn) {
						$currColumn = 0;
						$currIndex++;
					}
				} else {
					$maxIndex = $currIndex;
					$dataArrays{$currIndex} = [$1];
					$currColumn++;
					if($currColumn >= $maxColumn) {
						$currColumn = 0;
						$currIndex++;
					}
				}
			}
		} elsif($pltType eq "dc" && $mode eq "titles") {
			my $out = $_;
			$out =~ s/[\t \n]//g;
			if($out =~ /@/) {
				my $concat = $out;
				$concat =~ s/.*@(.*)/@\1/;
				$titleArray[@titleArray-1] .= $concat;
			}
			push(@titleArray, $out);
		} elsif($pltType eq "dc" && $mode eq "data") {
			$_ =~ /[ \t]*([0-9.eE+-]*)[ \t]*([0-9.eE+-]*)/;
			my @data = [ $1, $2 ];
			if(defined($dataArrays{$currIndex})) {
				push(@{$dataArrays{$currIndex}}, $1, $2);
				$currIndex++;
			} else {
				$maxIndex = $currIndex;
				$dataArrays{$currIndex} = [$1, $2];
				$currIndex++;
			}
		}
	}
}

close INFILE;

my $outfile = $ARGV[0];
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
