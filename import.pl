#!/usr/bin/perl

use OptionsXpress;
use TransactionSet;

my $file = 'account_analysis.xls';

my $ox = OptionsXpress->new($file);

my $ts = TransactionSet->new();

while (my $st = $ox->nextSt()) {
    $ts->add([$st]);
}

$ts->sortSt();
my $symbol = 'AAPL';
$ts->printSymbolTransactions($symbol);

$ts->accountSales($symbol);
