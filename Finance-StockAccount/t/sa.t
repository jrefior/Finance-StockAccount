use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount');

ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');

{
    my $atHash1 = {
        symbol          => 'GOOGL',
        dateString      => '20140220T093800Z',
        action          => 'buy',
        quantity        => 4,
        price           => 538,
        commission      => 10,
    };
    my $atHash2 = {
        symbol          => 'GOOGL',
        dateString      => '20140408T142600Z',
        action          => 'sell',
        quantity        => 4,
        price           => 569,
        commission      => 10,
    };
    my $atHash3 = {
        symbol          => 'INTC',
        dateString      => '20130427T120600Z',
        action          => 'buy',
        quantity        => 100,
        price           => 28.26,
        commission      => 10,
    };
    my $atHash4 = {
        symbol          => 'INTC',
        dateString      => '20140302T164500Z',
        action          => 'sell',
        quantity        => 100,
        price           => 33.06,
        commission      => 10,
    };
    ok($sa->stockTransaction($atHash1), 'Added new stock transaction.');
    ok(my $at = Finance::StockAccount::AccountTransaction->new($atHash2), 'Created new AccountTransaction object.');
    ok($sa->addAccountTransactions([$at]), 'Added $at object.');
    ok($sa->stockTransaction($atHash3), 'Added new stock transaction (3).');
    ok($sa->stockTransaction($atHash4), 'Added new stock transaction (4).');
    ok(my $roi = $sa->ROI(), 'Calculate Return on Investment.');
    print "ROI: $roi\n";
    ok(my $maroi = $sa->meanAnnualROI(), 'Calculate mean annual ROI.');
    print "Mean annual ROI: $maroi\n";
}



done_testing();
