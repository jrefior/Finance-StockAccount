use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Realization');

{
    my $initAt = {
        symbol          => 'ESI',
        action          => 'buy',
        price           => 7.89,
        quantity        => 200,
        commission      => 10,
    };
    my $shares = 100;
    ok(my $at = Finance::StockAccount::AccountTransaction->new($initAt), 'Created account transaction object.');
    ok(my $acquisition = Finance::StockAccount::Acquisition->new($at, $shares), 'Instantiated new Acquisition object.');
    is($at->cashEffect(), -1588, 'Got expected cash effect.');
    is($acquisition->cashEffect(), -794, 'Got expected proportion of cash effect.');
    is($acquisition->feesAndCommissions(), 5, 'Got expected proportion of fees and commissions.');
}


done_testing();
