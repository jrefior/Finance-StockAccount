use strict;
use warnings;

use Test::More;
use DateTime::Format::CLDR;

use_ok('Finance::StockAccount::Set');

{
    my $dateFormat = "M/d/yy";
    ok(my $cldr = DateTime::Format::CLDR->new(
        pattern     => $dateFormat,
        locale      => 'US_en',
        time_zone   => 'UTC',
      ), 'Created DateTime CLDR object.');
    ok(my $dt1 = $cldr->parse_datetime("1/31/12"), 'Instantiated dt1.');
    ok(my $dt2 = $cldr->parse_datetime("2/25/12"), 'Instantiated dt2.');
    ok(my $dt3 = $cldr->parse_datetime("3/11/12"), 'Instantiated dt3.');
    ok(my $dt4 = $cldr->parse_datetime("8/19/12"), 'Instantiated dt4.');
    ok(my $dt5 = $cldr->parse_datetime("9/21/12"), 'Instantiated dt5.');

    my $initAt1 = {
        symbol          => 'AMD',
        date            => $dt1,
        action          => 'buy',
        price           => 3.98,
        quantity        => 200,
        commission      => 10,
    };
    my $initAt2 = {
        symbol          => 'AMD',
        date            => $dt2,
        action          => 'buy',
        price           => 3.74,
        quantity        => 300,
        commission      => 10,
    };
    my $initAt3 = {
        symbol          => 'AMD',
        date            => $dt3,
        action          => 'buy',
        price           => 3.45,
        quantity        => 500,
        commission      => 10,
    };
    my $initAt4 = {
        symbol          => 'AMD',
        date            => $dt4,
        action          => 'sell',
        price           => 4.05,
        quantity        => 1000,
        commission      => 10,
    };
    my $initAt5 = {
        symbol          => 'AMD',
        date            => $dt5,
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


