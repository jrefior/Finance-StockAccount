#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('TransactionSet');

{
    my $ts = TransactionSet->new();
    ok($ts, 'New transaction set.');

    my $st1 = StockTransaction->new({date => '05/27/2012', quantity => 300, symbol => 'AAPL - APPLE INC', price => '$250.00', action => 'Buy'});
    my $st2 = StockTransaction->new({date => '05/21/2013', quantity => 400, symbol => 'AAPL - APPLE INC', price => '$300.00', action => 'Buy'});
    $ts->add([$st1, $st2]);
    is(scalar(@{$ts->{stBySymbol}{AAPL}}), 2, 'Found expected number of stock transactions.');

    my @dateSort = sort { $ts->cmpStDate($a, $b) } ($st1, $st2);
    is(scalar(@dateSort), 2, 'Date sort has right member count.');
    my $stA = $dateSort[0];
    is($stA->{quantity}, 300, 'Date sort sorted correctly.');

    my @priceSort = sort { $ts->cmpStPrice($a, $b) } ($st2, $st1);
    $stA = $priceSort[0];
    is($stA->{quantity}, 300, 'Price sort sorted correctly.');
}

done_testing();
