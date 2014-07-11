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

while (my $line = <$fh>) {
    chomp($line);
    my @row = split("\t", $line);
    pop(@row);


    my $row = {};
    for (my $x=0; $x<scalar(@headers); $x++) {
        if (exists($row[$x])) {
            $row->{$headers[$x]} = $row[$x];
        }
    }

    print $row->{'Symbol/Desc'}, "\n";
}



