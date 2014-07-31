package TransactionSet;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use StockTransaction;

my $tsPattern = "%20s %20s %20s\n";

sub new {
    my ($class, $init) = @_;
    my $self = {
        stBySymbol          => undef, # hash of arrays, e.g. {'AAPL' => [$st1, $st2, ...], ...}
        accountSets         => undef,
        stats               => undef,
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub add {
    my ($self, $transactions) = @_;
    ($transactions and 'ARRAY' eq ref($transactions))
        or die "TransactionSet->add([\$st1, \$st2, \$st3, ...]) ... method requires a reference to a list of st objects.\n";
    foreach my $st (@$transactions) {
       'StockTransaction' eq ref($st) or die "Not a valid st object.\n";
       push(@{$self->{stBySymbol}{$st->{symbol}}}, $st);
    }
}

sub cmpStDate {
    my ($self, $st1, $st2) = @_;
    my ($m1, $d1, $y1) = $st1->dateMDY();
    my ($m2, $d2, $y2) = $st2->dateMDY();
    if ($y1 == $y2) {
        if ($m1 == $m2) {
            if ($d1 == $d2) {
                return 0;
            }
            elsif ($d1 > $d2) {
                return 1;
            }
            else {
                return -1;
            }
        }
        elsif ($m1 > $m2) {
            return 1;
        }
        else {
            return -1;
        }
    }
    elsif ($y1 > $y2) {
        return 1;
    }
    else {
        return -1;
    }
}

sub cmpStPrice {
    my ($self, $st1, $st2) = @_;
    my $p1 = $st1->{price};
    my $p2 = $st2->{price};
    return $p1  > $p2 ? 1 :
           $p1 == $p2 ? 0 :
           -1;
}

sub available {
    my $self = shift;
    my $available = $self->{quantity} - $self->{accounted};
    return ($available > 0 ? $available : 0);
}

sub accountShares {
    my ($self, $shares) = @_;
    unless ($shares and $shares > 0) {
        warn "AccountShares of $shares bad input.\n";
        return 0;
    }
    my $available = $self->available();
    if (0 == $available) {
        warn "Requested accountShares but no shares available.\n";
        return 0;
    }
    elsif ($shares > $available) {
        $self->{accounted} = $self->{quantity};
        return $available;
    }
    else {
        $self->{accounted} += $shares;
        return $shares;
    }
}


sub sortSt {
    my $self = shift;
    foreach my $symbol (keys %{$self->{stBySymbol}}) {
        $self->{stBySymbol}{$symbol} = [sort { $self->cmpStDate($a, $b) } @{$self->{stBySymbol}{$symbol}}];
    }
    $self->{sorted} = 1;
    return 1;
}

sub printSymbolTransactions {
    my ($self, $symbol) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    print $symbol, "\n";
    foreach my $st (@$transactions) {
        $st->printTransaction();
    }
}

sub accountPriorPurchase {
    my ($self, $symbol, $index) = @_;
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
