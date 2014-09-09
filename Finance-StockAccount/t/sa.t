use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount');


{
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
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
    my $atHash3 = { # 2836
        symbol          => 'INTC',
        dateString      => '20130427T120600Z',
        action          => 'buy',
        quantity        => 100,
        price           => 28.26,
        commission      => 10,
    };
    my $atHash4 = { # 3296
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
    is($sa->profit(), 564, 'Got expected profit.');
    is($sa->minInvestment(), 4998, 'Got expected minimum cash investment that was required to achieve this profit.');
    ok($sa->ROI() =~ /^0\.112/, 'Got expected return on investment.');
    ok($sa->meanAnnualProfit() =~ /^595\./, 'Got expected mean annual profit.');
    ok($sa->meanAnnualROI() =~ /^0\.119/, 'Got expected mean annual ROI.');
    ok($sa->skipStocks(qw(GOOGL)), 'Add GOOGL to skipstocks list.');
    is($sa->profit(), 460, 'Got expected profit -- skipping GOOGL.');
    ok($sa->resetSkipStocks(), 'Reset skip stocks.');
    is($sa->profit(), 564, 'Including GOOGL again, got expected profit.');
}

{
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
    my $atHash1 = {};
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add empty stock transaction.');
    my $tm = Time::Moment->from_string('20120902T214500Z');
    $atHash1->{tm} = $tm;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date.');
    $atHash1->{symbol} = 'OOO';
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date and a symbol.');
    $atHash1->{action} = 'short';
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, and action.');
    $atHash1->{quantity} = 5;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, action, and quantity.');
    $atHash1->{price} = 0;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, action, quantity, and zero price.');
    $atHash1->{price} = 5;
    ok($sa->stockTransaction($atHash1), 'Was finally able to add my stock transaction!');
}

{
    my $atHash = {
        symbol          => 'AAA',
        dateString      => '20120421T193800Z',
        action          => 'buy',
        quantity        => 200,
        price           => 0,
        commission      => 0,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
    ok(!$sa->stockTransaction($atHash), 'Correctly failed to add stock transaction with price 0.');
    ok($sa = Finance::StockAccount->new({allowZeroPrice => 1}), 'Instantiated new StockAccount object with allowZeroPrice option turned on.');
    ok($sa->stockTransaction($atHash), 'Correctly added stock transaction with price 0 when allowZeroPrice set.');
    ok($sa->allowZeroPrice(), 'Got allowZeroPrice setting.');
    ok($sa->allowZeroPrice(0), 'Set allowZeroPrice setting.');
    ok(!$sa->allowZeroPrice(), 'Got value I set it to.');
}





done_testing();
