use strict;
use warnings;

use Test::More;

use Finance::StockAccount::Import::OptionsXpress;


my $allFile2014 = 'dlAllActivity201409.csv';

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($allFile2014, -240), 'Created new OX object for all activity as of September 2014.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok($sa->profit() =~ /^9960\.08/, 'Got expected profit.');
    ok($sa->minInvestment() =~ /^15989\./, 'Got expected minimum cash investment required to achieve this profit.');
    ok($sa->ROI() =~ /^0\.62/, 'Got expected ROI.');
    ok($sa->meanAnnualProfit() =~ /^4259\./, 'Got mean annual profit.');
    ok($sa->meanAnnualROI() =~ /^0\.26/, 'Got mean annual ROI.');
}

done_testing();
