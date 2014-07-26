#!/usr/bin/perl

use OptionsXpress;
use TransactionSet;

my $file = 'account_analysis.xls';

my $ox = OptionsXpress->new($file);

my $ts = TransactionSet->new();

while (my $st = $ox->nextSt()) {
    next if $st->{symbol} =~ /^(?:aet|aep|ab|ea|bac)$/i;
    $ts->add([$st]);
}

$ts->sortSt();
$ts->accountAllSales();
$ts->printTransactionSets();
