package Finance::StockAccount::Set;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use Finance::StockAccount::Transaction;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        accountTransactions => [],
        stats               =>
            {
                stale               => 1,
                sorted              => 0,
                profit              => 0,
                investment          => 0,
                return              => 0,
                ROI                 => 0,
            },
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub add {
    my ($self, $accountTransactions) = @_;
    ($accountTransactions and 'ARRAY' eq ref($accountTransactions))
        or die "TransactionSet->add([\$st1, \$st2, \$st3, ...]) ... method requires a reference to a list of st objects.\n";
    my $set = $self->{set};
    my $added = 0;
    my $stock = $self->{stock};
    foreach my $at (@$accountTransactions) {
        'Finance::StockAccount::AccountTransaction' eq ref($st) or die "Not a valid at object.\n";
        if (!$stock) {
            if ($stock = $at->stock()) {
                $self->{stock} = $stock;
            }
        }
        $stock->same($at->stock()) or die "Given Stock Transaction object does not match stock for set, or set stock is undefined.\n";
        push(@$set, $at);
        $added = 1;
    }
    if ($added) {
        $set->{stale} = 1;
    }
    return $added;
}

sub cmpStPrice {
    my ($self, $at1, $at2) = @_;
    my $p1 = $at1->{price};
    my $p2 = $at2->{price};
    return $p1  > $p2 ? 1 :
           $p1 == $p2 ? 0 :
           -1;
}

sub sortSt {
    my $self = shift;
    foreach my $symbol (keys %{$self->{stBySymbol}}) {
        $self->{stBySymbol}{$symbol} = [sort { $self->cmpStDate($a, $b) } @{$self->{stBySymbol}{$symbol}}];
    }
    $self->{sorted} = 1;
    return 1;
}

sub accountPriorPurchase {
    my ($self, $index) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    my @priorPurchases = sort { $self->cmpStPrice($a, $b) } grep { $_->possiblePurchase() } @{$transactions}[0 .. $index];
    my $sale = $transactions->[$index];
    my $set = {
        sale            => $sale,
        purchases       => [],
        saleValue       => 0,
        purchaseValue   => 0,
        realized        => undef,
    };
    foreach my $priorPurchase (@priorPurchases) {
        my $sharesSold = $sale->available();
        last unless $sharesSold;
        my $accounted = $priorPurchase->accountShares($sharesSold);
        if ($accounted) {
            push(@{$set->{purchases}}, $priorPurchase);
            $sale->accountShares($accounted);
            $set->{purchaseValue} += $priorPurchase->accountedValue();
        }
    }
    if (scalar(@{$set->{purchases}})) {
        $set->{saleValue} = $sale->accountedValue();
        $set->{realized} = $set->{saleValue} - $set->{purchaseValue};
        push(@{$self->{accountSets}{$symbol}}, $set);
    }
    return 1;
}

sub accountSales {
    my ($self, $symbol) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    my $sale;
    my $index = 0;
    for (my $x=0; $x<scalar(@$transactions); $x++) {
        my $st = $transactions->[$x];
        if ($st->isSale()) {
            if ($st->available()) {
                $self->accountPriorPurchase($symbol, $x);
            }
        }
    }
}

sub accountAllSales {
    my $self = shift;
    foreach my $symbol (keys %{$self->{stBySymbol}}) {
        $self->accountSales($symbol);
    }
    return 1;
}

sub printTransactionSets {
    my $self = shift;
    foreach my $symbol (sort keys %{$self->{accountSets}}) {
        print $symbol, ' ', '-'x10, "\n";
        my @totalValue = (0, 0, 0);
        foreach my $set (@{$self->{accountSets}{$symbol}}) {
            my $purchaseValue = $set->{purchaseValue};
            my $saleValue = $set->{saleValue};
            my $realized = $set->{realized};
            printf($tsPattern, map { StockTransaction->formatDollars($_) } ($purchaseValue, $saleValue, $realized));
            $totalValue[0] += $purchaseValue;
            $totalValue[1] += $saleValue;
            $totalValue[2] += $realized;
        }
        print '='x80, "\n";
        printf($tsPattern, map { StockTransaction->formatDollars($_) } @totalValue);
        print "\n\n";
    }
}

sub populateStats {
    my ($self, $symbol) = @_;
    my $sets = $self->{accountSets}{$symbol};
    my ($firstPurchaseDate, $finalSaleDate, $totalRealized);
    foreach my $set (@$sets) {
        my $sale = $set->{sale};
    }
}




1;
