use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Import::OptionsXpress');

my $aaplFile    = 'dlAppleActivity.csv';
my $allFile2014 = 'dlAllActivity201409.csv';
my $esiFile    = 'dlEsiActivity.csv';
my $eaFile    = 'dlEaActivity.csv';
my $aepFile    = 'dlAepActivity.csv';

{
    my $ox = Finance::StockAccount::Import::OptionsXpress->new($aaplFile, -240);

    ok($ox, 'Created new OX object with file.');

    my $st = $ox->nextAt();
    ok($st, 'Read first transaction line into a StockTransaction object.');

    $st->printTransaction();

    is($st->symbol(), 'AAPL', 'Symbol matches.');
    is($st->commission(), 8.95, 'Commission matches.');
}

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($aaplFile, -240), 'Created new OX object with file again.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok($sa->profit() =~ /^1382\.49/, 'Got expected profit.');
}

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($esiFile, -240), 'Created new OX object for ESI activity.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok(!($sa->profit()), 'Correctly failed to get profit for ESI (acquisitions only, no divestments).');
}

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($eaFile, -240), 'Created new OX object for EA activity.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok($sa->profit() =~ /^51\.803/, 'Got expected profit for EA (bought 93 shares, sold 193 shares).');
}

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($aepFile, -240), 'Created new OX object for AEP activity.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok(!($sa->profit()), 'Correctly failed to get profit profit for AEP (divestments only, no acquisitions).');
}

{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($allFile2014, -240), 'Created new OX object for all activity as of September 2014.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    # ok($sa->skipStocks([qw(AB BAC AET FTR AEP GOOG GOOGL NVDA S)]), 'Added skip stock hashkeys.');
    ok(my $profit = $sa->profit(), 'Got profit.');
    ok(my $meanROI = $sa->meanROI(), 'Got ROI.');
    ok(my $meanAnnualProfit = $sa->meanAnnualProfit(), 'Got mean annual profit.');

    my $pattern = "%30s: %10s\n";
    printf($pattern, 'Profit', $profit);
    printf($pattern, 'Mean ROI', $meanROI);
    printf($pattern, 'Mean Annual Profit', $meanAnnualProfit);
}




done_testing();
