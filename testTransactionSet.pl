#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('TransactionSet');
my $ts = TransactionSet->new();
ok($ts, 'New transaction set.');

done_testing();
