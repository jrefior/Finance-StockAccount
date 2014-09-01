use strict;
use warnings;

use Test::More;
use Time::Moment;

use_ok('Finance::StockAccount::Set');

{

    ok(my $tm1 = Time::Moment->from_string("20120131T000000Z"), 'Instantiated tm1 Time::Moment object.');

    my $initAt1 = {
        symbol          => 'AMD',
        tm              => $tm1,
        action          => 'buy',
        price           => 3.98,
        quantity        => 200,
        commission      => 10,
    };
    my $initAt2 = {
        symbol          => 'AMD',
        dateString      => "20120225T000000Z",
        action          => 'buy',
        price           => 3.74,
        quantity        => 300,
        commission      => 10,
    };
    my $initAt3 = {
        symbol          => 'AMD',
        dateString      => "20120311T000000Z",
        action          => 'buy',
        price           => 3.45,
        quantity        => 500,
        commission      => 10,
    };
    my $initAt4 = {
        symbol          => 'AMD',
        dateString      => "20120819T000000Z",
        action          => 'sell',
        price           => 4.05,
        quantity        => 1000,
        commission      => 10,
    };
    my $initAt5 = {
        symbol          => 'AMD',
        dateString      => "20120921T000000Z",
        action          => 'buy',
        price           => 3.89,
        quantity        => 200,
        commission      => 10,
    };

    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction 1.');
    ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction 2.');
    ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction 3.');
    ok(my $at4 = Finance::StockAccount::AccountTransaction->new($initAt4), 'Created account transaction 4.');
    ok(my $at5 = Finance::StockAccount::AccountTransaction->new($initAt5), 'Created account transaction 5.');

    ok(my $set = Finance::StockAccount::Set->new([$at2, $at5, $at4, $at3, $at1]), 'Instantiated new Set object.');
    ok($set->printTransactionDates(), 'Print transaction dates.');
    ok($set->accountSales(), 'Accounted for sales.');
    is($set->investment(), 3673, 'Cost (investment) as expected.');
    is($set->proceeds(), 4040, 'Benefit (proceeds) as expected.');
    is($set->profit(), 367, 'Profit as expected.');
    ok($set->roi() =~ /^0\.0999/, 'ROI as expected.');

}




    



done_testing();


