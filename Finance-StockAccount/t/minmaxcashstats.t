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

done_testing();
