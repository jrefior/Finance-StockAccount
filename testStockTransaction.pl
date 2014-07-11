#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('StockTransaction');

{
    my $date = '05/27/2012';
    my $st = StockTransaction->new({date => $date});
    is($st->{date}, $date, 'Date equivalency.');

    ok($st->set({price => '$4,321.01'}), 'Set a price.');
    is($st->{price}, 4321.01, 'Price equivalency.');
}

    



done_testing();


