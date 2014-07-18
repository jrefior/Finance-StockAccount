#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('StockTransaction');

{
    my $date = '05/27/2012';
    my $st = StockTransaction->new({date => $date});
    is($st->{date}, $date, 'Date equivalency.');
    my ($m, $d, $y) = $st->dateMDY();
    ok($m == 5, 'Month matches.');
    ok($d == 27, 'Day matches.');
    ok($y == 2012, 'Year matches.');

    my $ps = '$4,321.01';
    my $pn = 4321.01;
    ok($st->set({price => $ps}), 'Set a price.');
    is($st->{price}, $pn, 'Price equivalency.');
    is($st->formatDollars($st->{price}), $ps, 'Price string equivalency.');

    my $ss = 'AAPL - APPLE INC';
    ok($st->set({symbol => $ss}), 'Set a symbol');
    is($st->{symbol}, 'AAPL', 'Symbol extracted as expected.');

}

    



done_testing();


