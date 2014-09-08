#!/bin/env perl

use strict;
use warnings;

use Benchmark qw(timethis);
use Test::More;

use Finance::StockAccount;

{
    my $atHash = {
        symbol          => 'AAA',
        dateString      => '20120421T193800Z',
        action          => 'buy',
        quantity        => 200,
        price           => 47.63,
        commission      => 8.95,
    };
    my $sa = Finance::StockAccount->new();
    timethis(100000, sub { $sa->stockTransaction($atHash) }, 'Add Transaction');
}

