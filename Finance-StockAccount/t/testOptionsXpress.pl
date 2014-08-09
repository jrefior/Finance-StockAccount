#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('OptionsXpress');

my $file = 'account_analysis.xls';

my $ox = OptionsXpress->new($file);

ok($ox, 'Created new OX object with file.');

my $st = $ox->nextSt();
ok($st, 'Read first transaction line into a StockTransaction object.');
is($st->{symbol}, 'AAPL', 'Symbol matches.');
is($st->{commission}, 8.95, 'Commission matches.');



done_testing();
