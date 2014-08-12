#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Import::OptionsXpress');

my $aaplFile = 'dlAppleActivity.csv';

my $ox = Finance::StockAccount::Import::OptionsXpress->new($aaplFile);

ok($ox, 'Created new OX object with file.');

my $st = $ox->nextSt();
ok($st, 'Read first transaction line into a StockTransaction object.');

$st->printTransaction();

is($st->symbol(), 'AAPL', 'Symbol matches.');
is($st->commission(), 8.95, 'Commission matches.');



done_testing();
