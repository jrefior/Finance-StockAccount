#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Transaction');

{
    my $date = '05/27/2012';
    my $st = Finance::StockAccount::Transaction->new({date => $date});
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

    my $quant = 500;
    ok($st->set({quantity => $quant}), 'Set a quantity.');
    is($st->{quantity}, 500, 'Quantity expected.');

    my $action = 'Buy';
    ok($st->set({action => $action}), 'Set an action.');
    is($st->{action}, $action, 'Retrieve the action.');

    ok($st->set({commission => '$8.95'}), 'Set commission value.');

    is($st->available(), 500, 'Available expected 500.');
    is($st->accountShares(100), 100, 'Account shares expected 100.');
    is($st->possiblePurchase(), 1, 'Possible purchase.');
    is($st->available(), 400, 'Available expected after accounting shares.');
    is($st->accountedValue(), 432109.95, 'Accounted value expected.');
    is($st->accountShares(600), 400, 'Accounted for expected number when request was too high.');
    is($st->available(), 0, 'Available zero after accounting for all shares.');
    is($st->possiblePurchase(), 0, 'Not a possible purchase.');


}

    



done_testing();


