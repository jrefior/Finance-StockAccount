package Finance::StockAccount::Set;

use strict;
use warnings;

use Time::Moment;
use Carp;

use Finance::StockAccount::Realization;


sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        accountTransactions => [],
        realizations        => [],
        stats               => getNewStatsHash(),
        dateLimit           => {
            start               => undef,
            end                 => undef,
        },
        verbose             => 0,
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub getNewStatsHash {
    return {
        stale                       => 1,
        success                     => 0,
        profit                      => 0,
        totalOutlays                => 0,
        totalRevenues               => 0,
        commissions                 => 0,
        regulatoryFees              => 0,
        otherFees                   => 0,
        startDate                   => undef,
        endDate                     => undef,
        unrealizedTransactionCount  => 0,
    };
}

sub realizationCount {
    my $self = shift;
    return scalar(@{$self->{realizations}});
}

sub unrealizedTransactions {
    my $self = shift;
    return [grep { $_->accounted() == 0 } @{$self->{accountTransactions}}];
}

sub realizedTransactions {
    my $self = shift;
    return [grep { $_->accounted() > 0 } @{$self->{accountTransactions}}];
}

sub transactionCount {
    my $self = shift;
    my $count = 0;
    foreach my $at (@{$self->{accountTransactions}}) {
        $at->accounted() > 0 and $count++;
    }
    return $count;
}

sub unrealizedTransactionCount {
    my $self = shift;
    my $count = 0;
    foreach my $at (@{$self->{accountTransactions}}) {
        $at->accounted() == 0 and $count++;
    }
    return $count;
}

sub stale {
    my ($self, $assertion) = @_;
    if (defined($assertion)) {
        if ($assertion == 1 or $assertion == 0) {
            $self->{stats}{stale} = $assertion ? 1 : 0;
            return 1;
        }
        else {
            croak "Method 'stale' only accepts assertions in the form of 1 or 0 -- $assertion is not valid.";
        }
    }
    else {
        return $self->{stats}{stale};
    }
}

sub add {
    my ($self, $accountTransactions) = @_;
    ($accountTransactions and 'ARRAY' eq ref($accountTransactions))
        or confess "Set->add([\$st1, \$st2, \$st3, ...]) ... method requires a reference to a list of st objects.\n";
    my $set = $self->{accountTransactions};
    my $added = 0;
    my $stock = $self->{stock};
    foreach my $at (@$accountTransactions) {
        'Finance::StockAccount::AccountTransaction' eq ref($at) or confess "Not a valid at object.\n";
        if (!$stock) {
            if ($stock = $at->stock()) {
                $self->{stock} = $stock;
            }
        }
        $stock->same($at->stock()) or croak "Given Stock Transaction object does not match stock for set, or set stock is undefined.";
        push(@$set, $at);
        $added = 1;
    }
    if ($added) {
        $self->stale(1);
        $self->{dateSort} = 0;
    }
    return $added;
}

sub clearPastAccounting {
    my $self = shift;
    my $accountTransactions = $self->{accountTransactions};
    for (my $x=0; $x<scalar(@$accountTransactions); $x++) {
        my $at = $accountTransactions->[$x];
        $at->resetAccounted();
    }
    $self->{realizations} = [];
    $self->{stats} = $self->getNewStatsHash();
    $self->{stats}{success} = 0;
    return 1;
}

sub setDateLimit {
    my ($self, $tm1, $tm2) = @_;
    if ($tm1 > $tm2) {
        croak "The start date must come before the end date.";
    }
    my $dateLimit = $self->{dateLimit};
    $dateLimit->{start} = $tm1;
    $dateLimit->{end}   = $tm2;
    $self->{stats}{stale} = 1;
    return 1;
}

sub clearDateLimit {
    my $self = shift;
    my $dateLimit = $self->{dateLimit};
    $dateLimit->{start} = undef;
    $dateLimit->{end}   = undef;
    $self->{stats}{stale} = 1;
    return 1;
}

sub cmpPrice {
    my ($self, $at1, $at2) = @_;
    my $p1 = $at1->{price};
    my $p2 = $at2->{price};
    return $p1  > $p2 ? 1 :
           $p1 == $p2 ? 0 :
           -1;
}

sub dateSort {
    my $self = shift;
    $self->{accountTransactions} = [sort { $a->tm() <=> $b->tm() } @{$self->{accountTransactions}}];
    $self->{dateSort} = 1;
    return 1;
}

sub transactionDates {
    my $self = shift;
    my $transactionDates = [];
    foreach my $at (@{$self->{accountTransactions}}) {
        push(@$transactionDates, $at->tm());
    }
    return $transactionDates;
}

sub printTransactionDates {
    my $self = shift;
    my $transactionDates = $self->transactionDates();
    print join(', ', map { $_->to_string() } @$transactionDates), "\n";
    return 1;
}

sub dateLimitPortion {
    my ($self, $divestment, $acquisition) = @_;
    my $dateLimit = $self->{dateLimit};
    if (!$dateLimit->{start} or !$dateLimit->{end}) {
        return 1;
    }
    else {
        my $limitStart  = $dateLimit->{start};
        my $limitEnd    = $dateLimit->{end};
        my $realStart   = $acquisition->tm();
        my $realEnd     = $divestment->tm();
        my $startWithinLimit = ($realStart <= $limitEnd and $realStart >= $limitStart) ? 1 : 0;
        my $endWithinLimit   = ($realEnd   <= $limitEnd and $realEnd   >= $limitStart) ? 1 : 0;
        if ($startWithinLimit and $endWithinLimit) {
            return 1;
        }
        elsif ($realStart >= $limitEnd or $realEnd <= $limitStart) {
            return 0;
        }
        elsif (!$startWithinLimit and !$endWithinLimit) {
            my $limitRangeSeconds = $limitEnd->epoch() - $limitStart->epoch();
            my $realRangeSeconds  = $realEnd->epoch() - $realStart->epoch();
            return $limitRangeSeconds / $realRangeSeconds;
        }
        elsif ($startWithinLimit) {
            my $realRangeSeconds   = $realEnd->epoch() - $realStart->epoch();
            my $secondsWithinLimit = $limitEnd->epoch() - $realStart->epoch();
            return $secondsWithinLimit / $realRangeSeconds;
        }
        elsif ($endWithinLimit) {
            my $realRangeSeconds   = $realEnd->epoch() - $realStart->epoch();
            my $secondsWithinLimit = $realEnd->epoch() - $limitStart->epoch();
            return $secondsWithinLimit / $realRangeSeconds;
        }
        else {
            warn "Unexpected result from date comparisons when trying to calculate portion of realization within the given date limit.";
            return 0;
        }
    }
}

sub accountPriorPurchase {
    my ($self, $index) = @_;
    if (!$self->{dateSort}) {
        confess "Cannot account prior purchase when transactions have not been sorted by date.\n";
    }
    my $accountTransactions = $self->{accountTransactions};
    my $divestment = $accountTransactions->[$index];
    my $actionString = $divestment->actionString();
    my $realization = Finance::StockAccount::Realization->new({
        stock           => $divestment->stock(),
        divestment      => $divestment,
    });
    
    my @priorPurchases = sort { $self->cmpPrice($a, $b) } grep { $_->possiblePurchase($actionString) } @{$accountTransactions}[0 .. $index];
    foreach my $priorPurchase (@priorPurchases) {
        my $sharesDivested = $divestment->available();
        last unless $sharesDivested;
        my $accounted = $priorPurchase->accountShares($sharesDivested);
        if ($accounted) {
            my $acquisition = Finance::StockAccount::Acquisition->new($priorPurchase, $accounted);
            my $dateLimitPortion = $self->dateLimitPortion($divestment, $acquisition);
            $realization->addAcquisition($acquisition, $dateLimitPortion);
            $divestment->accountShares($accounted);
        }
    }

    if ($realization->acquisitionCount() and ($realization->costBasis() or $realization->revenue())) {
        push(@{$self->{realizations}}, $realization);
        $self->startDate($realization->startDate());
        $self->endDate($realization->endDate());
        my $stats = $self->{stats};
        $stats->{profit}            += $realization->realized();
        $stats->{totalOutlays}      += $realization->costBasis();
        $stats->{totalRevenues}     += $realization->revenue();
        $stats->{commissions}       += $realization->commissions();
        $stats->{regulatoryFees}    += $realization->regulatoryFees();
        $stats->{otherFees}         += $realization->otherFees();
        $stats->{success} = 1;
        return 1;
    }
    else {
        my $symbol = $divestment->symbol();
        $self->{verbose} and print "[Info] Unable to account for sold shares of symbol $symbol at index $index. There is no acquisition that matches this divestment.\n";
        return 0;
    }
}

sub accountSales {
    my $self = shift;
    $self->clearPastAccounting();
    if (!$self->{dateSort}) {
        $self->dateSort();
    }
    my $accountTransactions = $self->{accountTransactions};
    my $status = 0;
    for (my $x=0; $x<scalar(@$accountTransactions); $x++) {
        my $at = $accountTransactions->[$x];
        if ($at->sell() or $at->short()) {
            if ($at->available()) {
                $status += $self->accountPriorPurchase($x);
            }
        }
    }
    $self->stale(0);
    return $status;
}

sub startDate {
    my ($self, $tm) = @_;
    my $startDate = $self->{stats}{startDate};
    if ($tm) {
        if (!$startDate) {
            $self->{stats}{startDate} = $tm;
            return 1;
        }
        elsif ($tm < $startDate) {
            $self->{stats}{startDate} = $tm;
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return $startDate;
    }
}

sub endDate {
    my ($self, $tm) = @_;
    my $endDate = $self->{stats}{endDate};
    if ($tm) {
        if (!$endDate) {
            $self->{stats}{endDate} = $tm;
            return 1;
        }
        elsif ($tm > $endDate) {
            $self->{stats}{endDate} = $tm;
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return $endDate;
    }
}

sub checkStats {
    my $self = shift;
    if ($self->{stats}{stale}) {
        $self->accountSales();
    }
    return 1;
}

sub profitOverOutlays {
    my $self = shift;
    $self->checkStats();
    my $stats = $self->{stats};
    return $stats->{profit} / $stats->{totalOutlays};
}

sub profit {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{profit};
}

sub totalOutlays {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{totalOutlays};
}

sub totalRevenues {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{totalRevenues};
}

sub commissions {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{commissions};
}

sub regulatoryFees {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{regulatoryFees};
}

sub otherFees {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{otherFees};
}

sub success {
    my $self = shift;
    $self->checkStats();
    return $self->{stats}{success};
}

sub realizations {
    my $self = shift;
    $self->checkStats();
    return $self->{realizations};
}

sub realizationsString {
    my $self = shift;
    my $string;
    foreach my $realization (@{$self->{realizations}}) {
        $string .= '='x94 . "\n" . $realization->string() . "\n";
    }
    return $string;
}





1;
