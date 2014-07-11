#!/usr/bin/perl

package StockTransaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

sub new {
    my ($class, $init) = @_;
    my $self = {
        date        => $init->{date},
        action      => $init->{action},
        symbol      => $init->{symbol},
        quantity    => $init->{quantity},
        price       => $init->{price},
    };
    return bless($self, $class);
}

package main;
import StockTransaction;

#### Expected Fields, tab separated:
# Trade Date	Indicator	Action	Symbol/Desc	Qty	Price	Commission	Net Amount	Gain Loss	
# 0             1           2       3           4   5       6           7           8
my @pattern = qw(date 0 action 2 symbol 3 quantity 4 price 5);

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

    for (my $x=0; $x<scalar(@pattern)-1; $x+=2) {
        if (exists($row[$pattern[$x+1]])) {
        }
    }
}



