use strict;
use warnings;

use Test::More;
use Time::Moment;

use_ok('Finance::StockAccount::Set');

{

    ok(my $tm1 = Time::Moment->from_string("20120131T000000Z"), 'Instantiated tm1 Time::Moment object.');
    ok(my $tm4 = Time::Moment->from_string("20120819T000000Z"), 'Instantiated tm4 Time::Moment object.');
    ok(my $tm5 = Time::Moment->from_string("20120921T000000Z"), 'Instantiated tm5 Time::Moment object.');

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
        dateString      => $tm4,
        action          => 'sell',
        price           => 4.05,
        quantity        => 1000,
        commission      => 10,
    };
    my $initAt5 = {
        symbol          => 'AMD',
        dateString      => $tm5,
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
    ok($set->startDate() == $tm1, 'Got expected start date.');
    ok($set->endDate() == $tm4, 'Got expected end date.');
}

{
    my $initAt1 = {
        symbol          => 'AAA',
        dateString      => "20120721T182400Z",
        action          => 'buy',
        price           => 3.74,
        quantity        => 200,
        commission      => 10,
    };
    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction 1.');
    ok(my $stock = $at1->stock(), 'Got stock from AT object.');
    my $initAt2 = {
        stock           => $stock,
        dateString      => "20120815T141800Z",
        action          => 'buy',
        price           => 3.43,
        quantity        => 300,
        commission      => 10,
    };
    ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction 2.');
    my $initAt3 = {
        stock           => $stock,
        dateString      => "20121006T135300Z",
        action          => 'sell',
        price           => 3.97,
        quantity        => 500,
        commission      => 10,
    };
    ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction 3.');
    ok(my $set = Finance::StockAccount::Set->new([$at1, $at2, $at3]), 'Instantiated new Set object.');
    ok($set->accountSales(), 'Accounted sales.');
    is($set->profit(), 178, 'Got expected profit.');

    ok(my $tm1 = Time::Moment->from_string("20120601T000000Z"), 'Instantiated tm1 Time::Moment object.');
    ok(my $tm2 = Time::Moment->from_string("20121121T000000Z"), 'Instantiated tm2 Time::Moment object.');
    ok($set->setDateLimit($tm1, $tm2), 'Set date limit.');
    ok($set->clearPastAccounting(), 'Cleared past accounting.');
    ok($set->accountSales(), 'Accounted sales again.');
    is($set->profit(), 178, 'Got expected profit.');
}




    



done_testing();


