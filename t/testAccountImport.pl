#!/usr/bin/perl

use OptionsXpress;
use TransactionSet;

use Test::More;

my $file = 'testImportOptionsXpress.csv';

my $ox = OptionsXpress->new($file);
ok($ox, "Created new OptionsXpress object with $file.");

my $ts = TransactionSet->new();
ok($ts, 'Created new TransactionSet object.');

while (my $st = $ox->nextSt()) {
    next if $st->{symbol} =~ /^(?:aet|aep|ab|ea|bac)$/i;
    last unless $st->{symbol} eq 'AAPL';
    $ts->add([$st]);
}

is(@{$ts->{stBySymbol}{AAPL}}, 11, 'Imported expected number of trades.');

$ts->sortSt();
my $transactions = $ts->{stBySymbol}{AAPL};

my @dates = reverse(qw(
    05/27/2014
    05/07/2014
    04/30/2014
    01/28/2014
    01/03/2014
    12/18/2013
    10/18/2013
    09/16/2013
    09/13/2013
    07/01/2013
    06/28/2013
));

my $transactionCounter = 0;
for (my $dateCounter = 0; $dateCounter < scalar(@dates); $dateCounter++) {
    is($transactions->[$dateCounter]{date}, $dates[$dateCounter], "Expected date of transaction $dateCounter.");
}

is($transactions->[1]{price}, 408.3301, 'Got expected price value.');


$ts->accountAllSales();
$ts->printTransactionSets();

done_testing();
