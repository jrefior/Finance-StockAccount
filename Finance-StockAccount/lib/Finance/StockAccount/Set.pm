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
        success             => 0,
        stats               =>
            {
                stale               => 1,
                profit              => 0,
                investment          => 0,
                proceeds            => 0,
                ROI                 => 0,
                startDate           => undef,
                endDate             => undef,
            },
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub realizationCount {
    my $self = shift;
    return scalar(@{$self->{realizations}});
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

sub computeRoi {
    my $self = shift;
    $self->{stats}{ROI} = $self->{stats}{profit} / $self->{stats}{investment};
    return 1;
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
            $realization->addAcquisition($acquisition, $accounted);
            $divestment->accountShares($accounted);
        }
    }
    if ($realization->acquisitionCount()) {
        $realization->realize();
        push(@{$self->{realizations}}, $realization);
        $self->startDate($realization->startDate());
        $self->endDate($realization->endDate());
        $self->{stats}{profit} += $realization->realized();
        $self->{stats}{investment} += $realization->costBasis();
        $self->{stats}{proceeds} += $realization->proceeds();
        $self->computeRoi();
        $self->{success} = 1;
        return 1;
    }
    else {
        my $symbol = $divestment->symbol();
        print "[Info] Unable to account for sold shares of symbol $symbol at index $index. There is no acquisition that matches this divestment.\n";
        return 0;
    }
}

sub accountSales {
    my $self = shift;
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


sub profit              { return shift->{stats}{profit}                 };
sub investment          { return shift->{stats}{investment}             };
sub proceeds            { return shift->{stats}{proceeds}               };
sub roi                 { return shift->{stats}{ROI}                    };
sub success             { return shift->{success}                       };
sub realizations        { return shift->{realizations}                  };


1;
