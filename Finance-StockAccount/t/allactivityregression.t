use strict;
use warnings;

use Test::More;

use Finance::StockAccount::Import::OptionsXpress;


my $allFile2014 = 'dlAllActivity201409.csv';
my $printAnnualStats = 0;
my $printQuarterlyStats = 0;
my $printMonthlyStats = 1;

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($allFile2014, -240), 'Created new OX object for all activity as of September 2014.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok($sa->profit() =~ /^9960\.08/, 'Got expected profit.');
    ok($sa->maxCashInvested() =~ /^15989\./, 'Got expected max cash invested.');
    ok($sa->profitOverOutlays() =~ /^0\.62/, 'Got expected profit over outlays.');
    ok($sa->meanAnnualProfit() =~ /^4259\./, 'Got mean annual profit.');
    ok($sa->meanAnnualProfitOverOutlays() =~ /^0\.041/, 'Got expected mean annual profit over outlays.');
    ok($sa->meanAnnualProfitOverMaxCashInvested() =~ /^0\.26/, 'Got expected mean annual profit over max cash invested.');
    ok($sa->commissions() =~ /^976\.0/, 'Got expected commissions total.'); # old value 1038.2
    ok($sa->regulatoryFees() =~ /^2\.38/, 'Got expected regulatory fees total.'); # old value 2.42
    is($sa->otherFees(), 0, 'Got expected other fees total.');
    ok(my $annualStats = $sa->annualStats(), 'Calculated annual stats.');
    ok($annualStats->[0]{profit} =~ /^764\.5/, 'Got expected profit for 2012.');
    ok($annualStats->[1]{profit} =~ /^5871\.0/, 'Got expected profit for 2013.');
    ok($annualStats->[2]{profit} =~ /^3324\.4/, 'Got expected profit for 2014.');
    my $sumProfit = $annualStats->[0]{profit} + $annualStats->[1]{profit} + $annualStats->[2]{profit};
    ok($sumProfit =~ /^9960\./, 'Got expected total profit for all three years.');
    if ($printAnnualStats) {
        my $pattern = "%6s %10s %10s %10s\n";
        foreach my $yearStats (@$annualStats) {
            printf($pattern, $yearStats->{year}, $yearStats->{profit}, $yearStats->{profitOverOutlays}, $yearStats->{profitOverMaxCashInvested});
        }
    }
    ok(my $quarterlyStats = $sa->quarterlyStats(), 'Calculated quarterly stats.');
    ok($quarterlyStats->[4]{maxCashInvested} =~ /^13326\./, 'Got expected maxCashInvested for the fifth quarterly stats calculation.');
    if ($printQuarterlyStats) {
        foreach my $quarter (@$quarterlyStats) {
            printf("%4d %1d %6.3f %6.2f %-1.4f %-1.4f %-4.2f %-2.2f %-2.2f\n", $quarter->{year}, $quarter->{quarter},
                $quarter->{maxCashInvested}, $quarter->{profit}, $quarter->{profitOverOutlays}, $quarter->{profitOverMaxCashInvested},
                $quarter->{commissions}, $quarter->{regulatoryFees}, $quarter->{otherFees});
        }
    }
    if ($printMonthlyStats) {
        my @headings = qw(Year Month Outlays Revenues MaxInvested Profit OverOut OverInvested Commiss RegFees OthFees NumTrades);
        printf("%4s %5s %8s %8s %11s %8s %7s %12s %7s %7s %7s %9s\n", @headings);
        my $pattern = "%4d %5d %8.2f %8.2f %11.2f %8.2f %7.2f %12.2f %7.2f %7.2f %7.2f %9d\n";
        ok(my $monthlyStats = $sa->monthlyStats(), 'Calculated monthly stats.');
        foreach my $month (@$monthlyStats) {
            printf($pattern, $month->{year}, $month->{month}, $month->{totalOutlays}, $month->{totalRevenues}, $month->{maxCashInvested},
                $month->{profit}, $month->{profitOverOutlays}, $month->{profitOverMaxCashInvested}, $month->{commissions}, $month->{regulatoryFees},
                $month->{otherFees}, $month->{numberOfTrades});
        }
    }
}

done_testing();
