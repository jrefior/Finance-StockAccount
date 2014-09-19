use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Import::OptionsXpress');

my $aaplFile    = 'dlAppleActivity.csv';
my $esiFile     = 'dlEsiActivity.csv';
my $eaFile      = 'dlEaActivity.csv';
my $aepFile     = 'dlAepActivity.csv';
my $amdFile     = 'dlAmdActivity.csv';

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
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($amdFile, -240), 'Created new OX object for AMD activity.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    is($sa->profit(), 2803.63, 'Got expected profit for all AMD transactions.');
    is($sa->commissions(), 223.75, 'Got expected commissions for all AMD transactions.');
    is($sa->regulatoryFees(), 0.54, 'Got expected regulatory fees for all AMD transactions.');
    is($sa->maxCashInvested(), 6888.01, 'Got expected minimum cash investment that was required to reach that profit.');
}






done_testing();
