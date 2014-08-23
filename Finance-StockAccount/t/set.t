use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Set');

{
    my $initAt1 = {
        symbol          => 'ESI',
        action          => 'buy',
        price           => 7.89,
        quantity        => 200,
        commission      => 10,
    };
    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction 1.');
    ok(my $set = Finance::StockAccount::Set->new([$at1]), 'Instantiated new Set object.');

}




    



done_testing();


