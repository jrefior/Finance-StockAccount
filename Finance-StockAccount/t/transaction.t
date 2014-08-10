#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Transaction');

{
    my $st = Finance::StockAccount::Transaction->new();

    my $pn = 4321.01;
    ok($st->set({price => $pn}), 'Set a price.');
    is($st->{price}, $pn, 'Price equivalency.');

    ok($st->symbol('AAPL'), 'Set a stock');
    is($st->symbol(), 'AAPL', 'Symbol extracted as expected.');

    my $quant = 500;
    ok($st->set({quantity => $quant}), 'Set a quantity.');
    is($st->{quantity}, 500, 'Quantity expected.');

    my $action = 'Buy';
    ok($st->set({action => $action}), 'Set an action.');
    is($st->{action}, $action, 'Retrieve the action.');

    ok($st->set({commission => 8.95}), 'Set commission value.');
}

    



done_testing();


