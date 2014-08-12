use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Transaction');

{
    my $st = Finance::StockAccount::Transaction->new();

    my $pn = 510.10;
    ok($st->set({price => $pn}), 'Set a price.');
    is($st->{price}, $pn, 'Price equivalency.');

    ok($st->symbol('AAPL'), 'Set a stock symbol.');
    is($st->symbol(), 'AAPL', 'Symbol extracted as expected.');

    my $quant = 8;
    ok($st->set({quantity => $quant}), 'Set a quantity.');
    is($st->{quantity}, 8, 'Quantity expected.');

    ok($st->buy(1), 'Make it a buy.');
    ok($st->buy(), 'It is a buy.');
    ok(!$st->sell(), 'It is not a sell.');
    ok($st->sell(1), 'Make it a sell.');
    ok(!$st->buy(), 'It is not a buy.');
    ok($st->sell(), 'It is a sell.');
    ok($st->buy(1), 'Make it a buy again.');

    my $commission = 8.95;
    ok($st->set({commission => $commission}), 'Set commission value.');
    my $cashEffect = -1 * ($pn * $quant + $commission);
    is($st->cashEffect(), $cashEffect, 'Cash effect matches.');

    ok($st->printTransaction(), 'Printed the transaction.');
}


{
    my $hash = {
        symbol          => 'AMD',
        price           => 4.05,
        quantity        => 500,
    };
    my $st = Finance::StockAccount::Transaction->new($hash);
    ok($st, 'Instantiated new transaction object using a hash of parameters.');
    is($st->symbol(), 'AMD', 'Symbol matches.');
    is($st->price(), 4.05, 'Price matches.');
    is($st->quantity(), 500, 'Quantity matches.');
}

    



done_testing();


