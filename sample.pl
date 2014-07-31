

use StockAccount::Transaction;

my $st = StockAccount::Transaction->new({
    symbol              => 'AMD',
    price               => '$4.27',
    quantity            => 300,
    action              => 'sell',
    date                => '4/3/2014',
    commission          => '$8.95',
    regulatoryFees      => '$0.04',
});

if ($st->isSale()) {
    print $st->formatDollars($st->value()), "\n"; # $1,272.01
}

