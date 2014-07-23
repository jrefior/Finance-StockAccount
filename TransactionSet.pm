package TransactionSet;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use StockTransaction;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stBySymbol          => undef, # hash of arrays, e.g. {'AAPL' => [$st1, $st2, ...], ...}
        accountSets         => undef,
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

cmpStPrice {
    my ($self, $st1, $st2) = @_;
    my $p1 = $st1->{price};
    my $p2 = $st2->{price};
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

sub printSymbolTransactions {
    my ($self, $symbol) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    print $symbol, "\n";
    foreach my $st (@$transactions) {
        $st->printTransaction();
    }
}

sub lastSaleNotCounted {
    my ($self, $symbol) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    foreach my $st (@$transactions) {
        if ($st->isSale()) {
            if ($st->{accounted} < $st->{quantity}) {
                return $st;
            }
        }
    }
    return 0; # none found
}

sub accountPriorPurchase {
    my ($self, $symbol, $index) = @_;
    my $transactions = $self->{stBySymbol}{$symbol};
    my @priorPurchases = sort { $self->cmpStPrice($a, $b) } grep { $_->possiblePurchase() } @{$transactions}[0 .. $index];
    my $sale = $transactions->[$index];
    my $set = {sale => $sale, purchases => []};
    foreach my $priorPurchase (@priorPurchases) {
        my $sharesSold = $sale->available();
        last unless $sharesSold;
        my $accounted = $priorPurchase->accountShares($sharesSold);
        if ($accounted) {
            push(@{$set->{purchases}}, $priorPurchase);
            $sale->accountShares($accounted);
        }
    }
    push(@{$self->{accountSets}{$symbol}}, $set);
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




1;
