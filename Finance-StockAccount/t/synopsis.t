use strict;
use warnings;
use Test::More;


{
    use Finance::StockAccount;

    # One (fake) trade a day for a week in January...
    my $sa = Finance::StockAccount->new();
    $sa->stockTransaction({ # total cost: 1000
        symbol          => 'AAA',
        dateString      => '20140106T150500Z', 
        action          => 'buy',
        quantity        => 198,
        price           => 5,
        commission      => 10,
    });
    $sa->stockTransaction({ # total cost: 1000
        symbol          => 'BBB',
        dateString      => '20140107T150500Z', 
        action          => 'buy',
        quantity        => 99,
        price           => 10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total proceeds: 600 
        symbol          => 'AAA',
        dateString      => '20140108T150500Z', 
        action          => 'sell',
        quantity        => 100,
        price           => 6.10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total proceeds: 1070
        symbol          => 'BBB',
        dateString      => '20140109T150500Z', 
        action          => 'sell',
        quantity        => 99,
        price           => 11,
        commission      => 19,
    });
    $sa->stockTransaction({ # total proceeds: 670
        symbol          => 'AAA',
        dateString      => '20140110T150500Z', 
        action          => 'sell',
        quantity        => 98,
        price           => 7,
        commission      => 16,
    });

    my $profit              = $sa->profit();            # 340
    my $investment          = $sa->minInvestment();     # 2000
    my $ROI                 = $sa->ROI();               # 0.17
    my $meanAnnualProfit    = $sa->meanAnnualProfit();  # 31046.25


    is($profit, 340, 'Got expected profit.');
    is($investment, 2000, 'Got expected minimum investment required to reach that profit.');
    is($ROI, 0.17, 'Got expected ROI.');
    is($meanAnnualProfit, 31046.25, 'Got expected mean annual profit.  Doing pretty well for yourself!');
}

{
    # Alternatively, you can export an activity file from your online brokerage account
    # and then import that.  Only works for OptionsXpress so far, more to come.

    use Finance::StockAccount::Import::OptionsXpress;

    my $ox = Finance::StockAccount::Import::OptionsXpress->new('dlAmdActivity.csv');
    my $sa = $ox->stockAccount();
    my $profit = $sa->profit();     # 2803.63


    is($profit, 2803.63, 'Got expected profit from AMD activity file.');
}
 



done_testing();

# Any Time::Moment recognized date string, 
# in this case January 24, 2014 at 15:05 (3:05 PM) UTC
