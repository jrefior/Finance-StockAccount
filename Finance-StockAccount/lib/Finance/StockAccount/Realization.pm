package Finance::StockAccount::Realization;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use Finance::StockAccount::AccountTransaction;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock           => undef,
        sale            => $sale,
        purchases       => [],
        saleValue       => 0,
        purchaseValue   => 0,
        realized        => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub set {
    my ($self, $init) = @_;
    my $status = 1;
    foreach my $key (keys %{$init}) {
        if (exists($self->{$key})) {
            $self->{$key} = $init->{$key};
        }
        else {
            $status = 0;
            warn "Tried to set $key in Realization object, but that's not a known key.\n";
        }
    }
    return $status;
}


    my @priorPurchases = sort { $self->cmpStPrice($a, $b) } grep { $_->possiblePurchase() } @{$accountTransactions}[0 .. $index];
    my $sale = $accountTransactions->[$index];
    my $set = {
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
