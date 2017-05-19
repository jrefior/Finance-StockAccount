#!/usr/bin/perl

use strict;
use warnings;


use Test::More;

use_ok('Finance::StockAccount');
my $sa = Finance::StockAccount->new();

### Section 1: Get correct results for minCashRequired and maxCashInvested
### where all transactions are realized and overlapping.
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170501T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 200,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170502T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170503T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 210,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170504T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});

### Calculate max cash invested
# 5/1 we bought AAA for $2,005
# 5/2 we bought BBB for $1,005
# later we sold both.  Max cash invested was $3,010

is($sa->maxCashInvested(), 3010, "Calculated max cash invested where all transactions were realized.");
is($sa->minCashRequired(), 3010, "Calculated min cash required where expected to equal maxCashInvested.");

$sa = undef;

### Section 2: Get correct values for maxCashInvested and minCashRequired where two stocks are purchased
### but none are sold: no transactions are realized.
$sa = Finance::StockAccount->new();

$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170501T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 200,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170502T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});

is($sa->maxCashInvested(), 3010, "Calculated max cash invested where no transactions were realized.");
is($sa->minCashRequired(), 0, "Calculated min cash required where no transactions were realized.");

$sa = undef;

### Section 3: Get correct results for minCashRequired and maxCashInvested
### where all transactions are realized but realizations do not overlap.
$sa = Finance::StockAccount->new();

$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170501T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 200,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170502T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 210,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170503T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170504T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});

### Calculate max cash invested
# 5/1 we bought AAA for $2,005
# 5/2 we sold AAA for $2,095
# 5/3 we bought BBB for $1,005
# 5/4 we sold BBB for $995
# Max cash invested was $2,005
# Max cash required was $2,005

is($sa->maxCashInvested(), 2005, "Calculated max cash invested where all transactions were realized but realizations did not overlap.");
is($sa->minCashRequired(), 2005, "Calculated min cash required where expected to equal maxCashInvested.");

$sa = undef;

### Section 4: Get correct results for minCashRequired and maxCashInvested
### where all some transations are realized but realizations do not overlap,
### and another transaction is not realized.
$sa = Finance::StockAccount->new();

$sa->stockTransaction({
    symbol          => 'CCC',
    dateString      => '20170401T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 150,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170501T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 200,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170502T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 210,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170503T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170504T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 100,
    commission      => 5,
});

### Calculate max cash invested
# 4/1 we bought CCC for $1,505
# 5/1 we bought AAA for $2,005
# 5/2 we sold AAA for $2,095
# 5/3 we bought BBB for $1,005
# 5/4 we sold BBB for $995
# Max cash invested was $3,510
# Max cash required was $2,005

is($sa->maxCashInvested(), 3510, "Calculated max cash invested where some transactions were realized but realizations did not overlap, and another transaction was not realized.");
is($sa->minCashRequired(), 2005, "Calculated min cash required where one transaction was not realized.");

### Section 5: Check monthly stats for above example

### Periodic stats are based on realizations.  The above example only has realization-related data for May.  Everything's going to be in one month.
my $ms = $sa->monthlyStats();
is($ms->[0]{month}, 5, 'Found May as first month in monthly stats.');
my $may = $ms->[0];
is($may->{totalCostBasis}, 3010, 'Found expected May cost basis.');
ok($may->{profitOverCostBasis} =~ /0\.026/, 'Got expected May profit over cost basis.');

$sa = undef;

### Section 6: A more complex periodic test case
### compare results for periodic maxCashInvested and periodic minCashRequired
$sa = Finance::StockAccount->new();

### Let's come up with a reasonable pattern:
### Buy 10 shares AAA in April
### Buy 20 shares BBB in May
### Sell 5 shares AAA in May
### Buy 50 shares CCC in May
### Buy 10 shares AAA in June
### Sell 20 shares BBB in June
### Buy 10 shares BBB in June
### Make no trades in July
### Outstanding shares at this point: (AAA 15) ; (BBB 10) ; (CCC 50)
### In August, close position in BBB
### In September, close position in CCC and sell 10 shares AAA
### Left with 5 shares AAA
### End of data

# ci = cash invested
#ci +1505
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170401T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 150,
    commission      => 5,
});
#ci +2005
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170501T150500Z',
    action          => 'buy',
    quantity        => 20,
    price           => 100,
    commission      => 5,
});
#ci -805
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170502T150500Z',
    action          => 'sell',
    quantity        => 5,
    price           => 160,
    commission      => 5,
});
#ci +905
$sa->stockTransaction({
    symbol          => 'CCC',
    dateString      => '20170503T150500Z',
    action          => 'buy',
    quantity        => 50,
    price           => 18,
    commission      => 5,
});
#ci +1555
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170601T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 155,
    commission      => 5,
});
#ci -2205
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170602T150500Z',
    action          => 'sell',
    quantity        => 20,
    price           => 110,
    commission      => 5,
});
#ci +1055
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170603T150500Z',
    action          => 'buy',
    quantity        => 10,
    price           => 105,
    commission      => 5,
});
#ci
$sa->stockTransaction({
    symbol          => 'BBB',
    dateString      => '20170801T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 106,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'CCC',
    dateString      => '20170901T150500Z',
    action          => 'sell',
    quantity        => 50,
    price           => 18.50,
    commission      => 5,
});
$sa->stockTransaction({
    symbol          => 'AAA',
    dateString      => '20170902T150500Z',
    action          => 'sell',
    quantity        => 10,
    price           => 157,
    commission      => 5,
});

### Calculate max cash invested




done_testing();
