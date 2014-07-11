#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;

my $file = 'account_analysis.xls';

open my $fh, '<', $file or die "Failed to open $file: $!.\n";

my $hline = <$fh>;
chomp($hline);
my @headers = split("\t", $hline);
pop(@headers);
<$fh>;

while my ($line = <$fh>) {
    chomp($line);
    my @row = split("\t", $line);
    pop(@row);




