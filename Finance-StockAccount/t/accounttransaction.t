use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::AccountTransaction');

my $print = 1;

{
    my $init = {
        price       => 535.75,
        symbol      => 'AAPL',
        quantity    => 4,
        commission  => 10,
    };
    my $at = Finance::StockAccount::AccountTransaction->new($init);
    eval {
        $at->sell();
    };
    ok($@ =~ /^Action has not yet been set/, 'Received expected error getting action without setting action first.');
    ok($at->buy(1), 'Set action to buy.');
    ok($at->available(), "Shares are available.");
    ok($at->possiblePurchase('sell'), 'Transaction is a possible purchase.');
    is($at->accountShares(3), 3, 'Accounted expected number of shares.');
    is($at->available(), 1, 'Got expected number of available shares.');
    ok($at->possiblePurchase('sell'), 'Transaction is still a possible purchase.');
}
{
    ok(my $at = Finance::StockAccount::AccountTransaction->new({
        price           => 100,
        symbol          => 'AAA',
        quantity        => 10,
        commission      => 10,
        action          => 'buy',
        regulatoryFees  => 10,
        otherFees       => 10,
    }), 'Created new AT object.');
    ok($at->accountShares(5), 'Accounted half the shares.');
    is($at->proportion, '0.5', 'Got expected proportion.');
    is($at->quantity(), 5, 'Got expected quantity.');
    is($at->commission(), 5, 'Got expected commission.');
    is($at->regulatoryFees(), 5, 'Got expected regulatory fees.');
    is($at->otherFees(), 5, 'Got expected other fees.');
    is($at->cashEffect(), -515, 'Got expected cash effect.');
    ok($at->lineFormatValues(), 'Retrieved line format values.');
    ok(my $lineFormatString = $at->lineFormatString(), 'Created line format string.');
    if ($print) {
        print $lineFormatString;
    }
}



done_testing();


