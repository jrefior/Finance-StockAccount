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
    ok($sa->stockTransaction($atHash1), 'Added new stock transaction.');
    ok(my $at = Finance::StockAccount::AccountTransaction->new($atHash2), 'Created new AccountTransaction object.');
    ok($sa->addAccountTransactions([$at]), 'Added $at object.');
}



done_testing();
