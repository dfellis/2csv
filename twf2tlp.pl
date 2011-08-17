#!/usr/bin/perl

use Text::CSV;

my $user = getlogin();
my $pid = $PID;
my $tmp;
if($OSNAME eq "MSWin32") {
	$tmp = "C:/temp/$user-twf2tlp-$pid";
} else {
	$tmp = "/tmp/$user-twf2tlp-$pid";
}
my $diedie = "Invalid input! Example format:\ntwf2tlp twffile.twf vmode imode tlpfile.tlp\nvmode can take on the values vmaxv, vmaxi, vmaxp, and vavgX-Y where X and Y are times within the pulse. A similar set of commands exists for imode.\n";
#Input validation
if(@ARGV != 4) {
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
if($ARGV[3] =~ /\//) {
	$nwd = $ARGV[3]; $outfile = $ARGV[3];
	$nwd =~ s/(.*)\/[^\/]*$/\1/;
	$outfile =~ s/.*\/([^\/]*)$/\1/;
} else {
	$nwd = $pwd;
	$outfile = $ARGV[3];
}

my $infile = $ARGV[0];
my $vmode;
my $imode;
if($ARGV[1] =~ m/^v/) {
	$vmode = $ARGV[1];
	$imode = $ARGV[2];
} elsif($ARGV[1] =~ m/^i/) {
	$vmode = $ARGV[2];
	$imode = $ARGV[1];
} else {
	die $diedie;
}

mkdir("$tmp");
system "cp \"$pwd/$infile\" $tmp";
system "cd $tmp; twf2csv \"$infile\"";
my $csvfile = $infile . ".csv";

my $csv = Text::CSV->new();

open(CSV, "$tmp/$csvfile") or die "Could not generate the temporary csv file! $!";

my $firstline = 1;
my @columnheaders;
my %data;

while(<CSV>) {
	if($csv->parse($_)) {
		my @columns = $csv->fields();
		if($firstline == 1) {
			$firstline = 0;
			@columnheaders = @columns;
		} else {
			for($i = 0; $i < @columns; $i++) {
				push(@{$data{$columnheaders[$i]}},@columns[$i]);
			}
		}
	} else {
		my $err = $csv->error_input;
		print "Failed to parse line: $err\n";
	}
}

close(CSV);

my @pdata;
my @vdata;
my @idata;

for($i = 2; $columnheaders[$i] =~ m/^V/; $i++) {
	my $pulse = $columnheaders[$i]; $pulse =~ s/^V(.*)V$/\1/; $pulse += 0;
	push(@pdata, $pulse);
	my @tempArray1 = @{$data{$columnheaders[$i]}};
	my $corollary = $columnheaders[$i]; $corollary =~ s/^V/I/;
	my @tempArray2 = @{$data{$corollary}};
	my $tempVValue = "null";
	my $tempIValue = "null";
	if($vmode eq "vmaxv") {
		for($j = 0; $j < @tempArray1; $j++) {
			if($tempArray1[$j] > $tempVValue || $tempVValue eq "null") {
				$tempVValue = $tempArray1[$j];
			}
		}
	} elsif($vmode eq "vmaxi") {
		my $maxI = "null";
		for($j = 0; $j < @tempArray2; $j++) {
			if($tempArray2[$j] > $maxI || $maxI eq "null") {
				$tempVValue = $tempArray1[$j];
				$maxI = $tempArray2[$j];
			}
		}
	} elsif($vmode eq "vmaxp") {
		my $maxP = "null";
		for($j = 0; $j < @tempArray1; $j++) {
			if(abs($tempArray1[$j]*$tempArray2[$j]) > $maxP || $maxP eq "null") {
				$tempVValue = $tempArray1[$j];
				$maxP = abs($tempArray1[$j]*$tempArray2[$j]);
			}
		}
	} elsif($vmode eq "vminv") {
		for($j = 0; $j < @tempArray1; $j++) {
			if($tempArray1[$j] < $tempVValue || $tempVValue eq "null") {
				$tempVValue = $tempArray1[$j];
			}
		}
	} elsif($vmode eq "vmini") {
		my $minI = "null";
		for($j = 0; $j < @tempArray2; $j++) {
			if($tempArray2[$j] < $minI || $minI eq "null") {
				$tempVValue = $tempArray1[$j];
				$minI = $tempArray2[$j];
			}
		}
	} elsif($vmode eq "vminp") {
		my $minP = "null";
		for($j = 0; $j < @tempArray1; $j++) {
			if(abs($tempArray1[$j]*$tempArray2[$j]) < $minP || $minP eq "null") {
				$tempVValue = $tempArray1[$j];
				$minP = abs($tempArray1[$j]*$tempArray2[$j]);
			}
		}
	} elsif($vmode =~ m/^vavg/) {
		my @timeTempArray = @{$data{"timeV"}};
		my $startTime;
		my $endTime;
		$vmode =~ m/^vavg(.*),(.*)$/;
		$startTime = $1+0; $endTime = $2+0;
		if($startTime > $endTime) { #May as well handle idiocy gracefully
			$startTime += $endTime;
			$endTime = $startTime - $endTime;
			$startTime -= $endTime;
		}
		my $initialIndex = "null";
		my $finalIndex;
		for($finalIndex = 0; $timeTempArray[$finalIndex] < $endTime; $finalIndex++) {
			if($initialIndex eq "null" && $timeTempArray[$finalIndex] >= $startTime) {
				$initialIndex = $finalIndex;
			}
		} #I think this is pretty clever...
		$tempVValue = 0;
		for($j = $initialIndex; $j <= $finalIndex; $j++) {
			$tempVValue += $tempArray1[$j];
		}
		$tempVValue = $tempVValue / ($finalIndex - $initialIndex + 1);
	} elsif($vmode =~ m/^vmaxvavg/) {
		my $nodeCount;
		$vmode =~ m/^vmaxvavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVal += $tempArray1[$k];
			}
			$avgVal /= $nodeCount;
			if($avgVal > $tempVValue || $tempVValue eq "null") {
				$tempVValue = $avgVal;
			}
		}
	} elsif($vmode =~ m/^vmaxiavg/) {
		my $nodeCount;
		$vmode =~ m/^vmaxiavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $maxI = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgIVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgIVal += $tempArray2[$k];
			}
			$avgVVal /= $nodeCount;
			$avgIVal /= $nodeCount;
			if($avgIVal > $maxI || $maxI eq "null") {
				$maxI = $avgIVal;
				$tempVValue = $avgVVal;
			}
		}
	} elsif($vmode =~ m/^vmaxpavg/) {
		my $nodeCount;
		$vmode =~ m/^vmaxpavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $maxP = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgPVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgPVal += abs($tempArray1[$k]*$tempArray2[$k]);
			}
			$avgVVal /= $nodeCount;
			$avgPVal /= $nodeCount;
			if($avgPVal > $maxP || $maxP eq "null") {
				$maxP = $avgPVal;
				$tempVValue = $avgVVal;
			}
		}
	} elsif($vmode =~ m/^vminvavg/) {
		my $nodeCount;
		$vmode =~ m/^vminvavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVal += $tempArray1[$k];
			}
			$avgVal /= $nodeCount;
			if($avgVal < $tempVValue || $tempVValue eq "null") {
				$tempVValue = $avgVal;
			}
		}
	} elsif($vmode =~ m/^vminiavg/) {
		my $nodeCount;
		$vmode =~ m/^vminiavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $minI = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgIVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgIVal += $tempArray2[$k];
			}
			$avgVVal /= $nodeCount;
			$avgIVal /= $nodeCount;
			if($avgIVal < $minI || $minI eq "null") {
				$minI = $avgIVal;
				$tempVValue = $avgVVal;
			}
		}
	} elsif($vmode =~ m/^vminpavg/) {
		my $nodeCount;
		$vmode =~ m/^vminpavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $minP = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgPVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgPVal += abs($tempArray1[$k]*$tempArray2[$k]);
			}
			$avgVVal /= $nodeCount;
			$avgPVal /= $nodeCount;
			if($avgPVal < $minP || $minP eq "null") {
				$minP = $avgPVal;
				$tempVValue = $avgVVal;
			}
		}
	}
	if($imode eq "imaxv") {
		my $maxV;
		for($j = 0; $j < @tempArray1; $j++) {
			if($tempArray1[$j] > $maxV || $maxV eq "null") {
				$tempIValue = $tempArray2[$j];
				$maxV = $tempArray1[$j];
			}
		}
	} elsif($imode eq "imaxi") {
		for($j = 0; $j < @tempArray2; $j++) {
			if($tempArray2[$j] > $tempIValue || $tempIValue eq "null") {
				$tempIValue = $tempArray2[$j];
			}
		}
	} elsif($imode eq "imaxp") {
		my $maxP = "null";
		for($j = 0; $j < @tempArray2; $j++) {
			if(abs($tempArray1[$j]*$tempArray2[$j]) > $maxP || $maxP eq "null") {
				$tempIValue = $tempArray2[$j];
				$maxP = abs($tempArray1[$j]*$tempArray2[$j]);
			}
		}
	} elsif($imode eq "iminv") {
		my $minV;
		for($j = 0; $j < @tempArray1; $j++) {
			if($tempArray1[$j] < $minV || $minV eq "null") {
				$tempIValue = $tempArray2[$j];
				$minV = $tempArray1[$j];
			}
		}
	} elsif($imode eq "imini") {
		for($j = 0; $j < @tempArray2; $j++) {
			if($tempArray2[$j] < $tempIValue || $tempIValue eq "null") {
				$tempIValue = $tempArray2[$j];
			}
		}
	} elsif($imode eq "iminp") {
		my $minP = "null";
		for($j = 0; $j < @tempArray2; $j++) {
			if(abs($tempArray1[$j]*$tempArray2[$j]) < $minP || $minP eq "null") {
				$tempIValue = $tempArray2[$j];
				$minP = abs($tempArray1[$j]*$tempArray2[$j]);
			}
		}
	} elsif($imode =~ m/^iavg/) {
		my @timeTempArray = @{$data{"timeI"}};
		my $startTime;
		my $endTime;
		$imode =~ m/^iavg(.*),(.*)$/;
		$startTime = $1+0; $endTime = $2+0;
		if($startTime > $endTime) { #May as well handle idiocy gracefully
			$startTime += $endTime;
			$endTime = $startTime - $endTime;
			$startTime -= $endTime;
		}
		my $initialIndex = "null";
		my $finalIndex;
		for($finalIndex = 0; $timeTempArray[$finalIndex] < $endTime; $finalIndex++) {
			if($initialIndex eq "null" && $timeTempArray[$finalIndex] >= $startTime) {
				$initialIndex = $finalIndex;
			}
		} #I think this is pretty clever...
		$tempIValue = 0;
		for($j = $initialIndex; $j <= $finalIndex; $j++) {
			$tempIValue += $tempArray2[$j];
		}
		$tempIValue = $tempIValue / ($finalIndex - $initialIndex + 1);
	} elsif($imode =~ m/^imaxvavg/) {
		my $nodeCount;
		$imode =~ m/^imaxvavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $maxV = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgIVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgIVal += $tempArray2[$k];
			}
			$avgVVal /= $nodeCount;
			$avgIVal /= $nodeCount;
			if($avgVVal > $maxV || $maxV eq "null") {
				$maxV = $avgVVal;
				$tempIValue = $avgIVal;
			}
		}
	} elsif($imode =~ m/^imaxiavg/) {
		my $nodeCount;
		$imode =~ m/^imaxiavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		for($j = $buffer; $j < @tempArray2 - $buffer; $j++) {
			my $avgVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVal += $tempArray2[$k];
			}
			$avgVal /= $nodeCount;
			if($avgVal > $tempIValue || $tempIValue eq "null") {
				$tempIValue = $avgVal;
			}
		}
	} elsif($imode =~ m/^imaxpavg/) {
		my $nodeCount;
		$imode =~ m/^imaxpavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $maxP = "null";
		for($j = $buffer; $j < @tempArray2 - $buffer; $j++) {
			my $avgIVal = 0;
			my $avgPVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgIVal += $tempArray2[$k];
				$avgPVal += abs($tempArray1[$k]*$tempArray2[$k]);
			}
			$avgIVal /= $nodeCount;
			$avgPVal /= $nodeCount;
			if($avgPVal > $maxP || $maxP eq "null") {
				$maxP = $avgPVal;
				$tempIValue = $avgIVal;
			}
		}
	} elsif($imode =~ m/^iminvavg/) {
		my $nodeCount;
		$imode =~ m/^iminvavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $minV = "null";
		for($j = $buffer; $j < @tempArray1 - $buffer; $j++) {
			my $avgVVal = 0;
			my $avgIVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVVal += $tempArray1[$k];
				$avgIVal += $tempArray2[$k];
			}
			$avgVVal /= $nodeCount;
			$avgIVal /= $nodeCount;
			if($avgVVal < $minV || $minV eq "null") {
				$minV = $avgVVal;
				$tempIValue = $avgIVal;
			}
		}
	} elsif($imode =~ m/^iminiavg/) {
		my $nodeCount;
		$imode =~ m/^iminiavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		for($j = $buffer; $j < @tempArray2 - $buffer; $j++) {
			my $avgVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgVal += $tempArray2[$k];
			}
			$avgVal /= $nodeCount;
			if($avgVal < $tempIValue || $tempIValue eq "null") {
				$tempIValue = $avgVal;
			}
		}
	} elsif($imode =~ m/^iminpavg/) {
		my $nodeCount;
		$imode =~ m/^iminpavg(.*)$/;
		$nodeCount = $1+0;
		if(!($nodeCount % 2)) {
			$nodeCount++; #Make nodeCount odd
		}
		my $buffer = ($nodeCount - 1) / 2;
		my $minP = "null";
		for($j = $buffer; $j < @tempArray2 - $buffer; $j++) {
			my $avgIVal = 0;
			my $avgPVal = 0;
			for($k = $j - $buffer; $k < $j + $buffer; $k++) {
				$avgIVal += $tempArray2[$k];
				$avgPVal += abs($tempArray1[$k]*$tempArray2[$k]);
			}
			$avgIVal /= $nodeCount;
			$avgPVal /= $nodeCount;
			if($avgPVal < $minP || $minP eq "null") {
				$minP = $avgPVal;
				$tempIValue = $avgIVal;
			}
		}
	}
	push(@vdata,$tempVValue);
	push(@idata,$tempIValue);
}

open(OUTFILE, ">$nwd/$outfile") or die "Cannot create TLP file: $!";

print OUTFILE "TLP file name\t$outfile\n";
print OUTFILE "Wfm file name\t$infile\n";
print OUTFILE "Customer\t\n";
print OUTFILE "Technology/Test Chip:\t\n";
print OUTFILE "Package/Wafer ID:\t\n";
print OUTFILE "Device ID/Location:\t\n";
print OUTFILE "Pulse Pin:\t\n";
print OUTFILE "Ground Pins:\t\n";
print OUTFILE "Device Type:\t\n";
print OUTFILE "Test ended when:\t\n";
print OUTFILE "Leakage Test Voltage:\t\n";
print OUTFILE "Leakage Current Limit:\t\n";
print OUTFILE "Maximum Pulse Voltage:\t\n";
print OUTFILE "Start Pulse Voltage:\t\n"; #This can be filled in.
print OUTFILE "Test Step Voltage:\t\n"; #This could possibly be filled in.
print OUTFILE "Pulse Current Limit\t\n";
print OUTFILE "Pulse Width\t\n"; #This could be filled in, maybe.
print OUTFILE "Pulse Risetime\t\n"; #If the above is, so could this.
print OUTFILE "Start Measurement Window\t\n"; #If the above are filled in, then so could this.
print OUTFILE "End Measurement Window\t\n"; #Second verse, same as the first...
print OUTFILE "short cal V/A\t\n";
print OUTFILE "open cal A/V\t\n";
print OUTFILE "Voltage probe VR\t\n";
print OUTFILE "Current probe VR\t\n";
print OUTFILE "Cable(s), Socket used:\t\n";
print OUTFILE "Scope SPC last performed on:\t\n";
print OUTFILE "Version\t4.26\n";
print OUTFILE "Multi-Leakage\tNo(StartV/StopV/Steps)\t0.000E+0\t0.000E+0\t0\n";
print OUTFILE "Pulse V(Volts)\tV DUT(Volts)  \tI DUT(Amps) \tI(SP LEAKAGE)\t\n";

for($i = 0; $i < @pdata; $i++) {
	my $pulse = $pdata[$i];
	my $vdut = $vdata[$i];
	my $idut = $idata[$i];
	#print "$pulse\t$vdut\t$idut\n";
	my $outtext .= sprintf("%.4E\t%.4E\t%.4E\t%.4E\n", $pulse,$vdut,$idut,0);
	print OUTFILE "$outtext";
}

close(OUTFILE);

system("rm -rf $tmp");