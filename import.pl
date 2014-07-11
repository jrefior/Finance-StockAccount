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
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub set {
    my ($self, $init) = @_;
    for my $key (keys %init) {
        if (exists($self->{$key})) {
            $self->{$key} = $init->{$key};
        }
        else {
            warn "Tried to set $key, but that's not a known key.\n";
        }
    }
    return 1;
}
    
package OptionsXPress;
use Exporter 'import';
@EXPORT_OK = qw(new);
import StockTransaction;

#### Expected Fields, tab separated:
# Trade Date	Indicator	Action	Symbol/Desc	Qty	Price	Commission	Net Amount	Gain Loss	
# 0             1           2       3           4   5       6           7           8
my @pattern = qw(date 0 action 2 symbol 3 quantity 4 price 5);

sub new {
    my ($class, $file) = @_;
    my $self = {
        file                => $file,
        fh                  => undef,
    };
    bless($self, $class);
    $self->init();
    return $self;
}


package main;
import OptionsXPress;

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



