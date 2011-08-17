#!/usr/bin/perl

#DC PLT to CSV

my @titleArray;
my %dataArrays;
my $maxIndex = 0;
my $currIndex = 0;

open(INFILE, "$ARGV[0]") or die "Can't open $ARGV[0]: $!";

my $mode = "null";
while(<INFILE>) {
	if($_ =~ /.scan merge/) {
		$mode = "null";
		$currIndex = 0;
	} elsif($_ =~ /.vars/) {
		$mode = "titles";
	} elsif($_ =~ /.data/) {
		$mode = "data";
	} else {
		if($mode eq "null") {
			#Do nothing
		} elsif($mode eq "titles") {
			my $out = $_;
			$out =~ s/[\t \n]//g;
			if($out =~ /@/) {
				my $concat = $out;
				$concat =~ s/.*@(.*)/@\1/;
				$titleArray[@titleArray-1] .= $concat;
			}
			push(@titleArray, $out);
		} elsif($mode eq "data") {
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
$outfile =~ s/plt/csv/;

open(OUTFILE, ">$outfile") or die "Can't create output file: $!";

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
