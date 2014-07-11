#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('StockTransaction');

{
    my $date = '05/27/2012';
    my $st = StockTransaction->new({date => $date});
    is($st->{date}, $date, 'Date equivalency.');
}

    



done_testing();


