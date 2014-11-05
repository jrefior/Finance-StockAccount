package Finance::StockAccount::Set;

use strict;
use warnings;

use Time::Moment;
use Carp;

use Finance::StockAccount::Realization;

our $VERSION = '0.01';

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

sub symbol {
    my $self = shift;
    my $stock = $self->{stock};
    return $stock->symbol();
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

sub oneLinerSpacer {
    return '-'x80 . "\n";
}

sub oneLinerHeader {
    my $self = shift;
    return sprintf("%-6s %7s %12s %12s %39s\n", qw(Symbol ROI Outlays Revenues Profit));
}

sub oneLiner {
    my $self = shift;
    return sprintf("%-6s %7.2f %12.2f %12.2f %39.2f\n", $self->symbol(), $self->profitOverOutlays(), $self->totalOutlays(), $self->totalRevenues(), $self->profit());
}


1;


__END__

=head1 NAME

Finance::StockAccount::Set - a one-stock building block used by Finance::StockAccount

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Finance::StockAccount::Set objects are the building blocks of a
Finance::StockAccount object.  Each Set is the complete record of transactions
and accounting for a particular stock. Sets are also collections of
Realizations.  See perldoc Finance::StockAccount for context. 

Typical usage of sets involves adding Finance::StockAccount::Transaction
objects to them, analyzing them with the accountSales method, and then
retriving stats from them:

    my $at = Finance::StockAccount::AccountTransaction->new($init);
    my $set = Finance::StockAccount::Set->new([$at]);
    $set->accountSales();
    my $profit = $set->profit();

=head1 METHODS

=head2 realizations

    my $realizations = $set->realizations();

Returns a reference to an array of all realizations in the set.  Like the other
methods concerning realizations below, this is only meaningful after
$set->accountSales() has been run.

=head2 realizationCount

    my $realizationCount = $set->realizationCount();

Answers the question: how many realizations are in the set?

=head2 transactionCount

    my $transactionCount = $set->transactionCount();

How many realized transactions are in the set?

=head2 unrealizedTransactionCount

    my $unrealizedTransactionCount = $set->unrealizedTransactionCount();

How many unrealized transactions are in the set?

=head2 realizedTransactions

    my $realizedTransactions = $set->realizedTransactions();

Returns a reference to the array of all realized transactions in the set.

=head2 unrealizedTransactions

    my $unrealizedTransactions = $set->unrealizedTransactions();

Returns a reference to the array of all unrealized transactions in the set.

=head2 stale

    $set->stale() and $set->accountSales();

Returns true if the Set object has changed in a significant way since the last
accountSales() call, false otherwise.  If called with a parameter, can also be
used to set the staleness status of the set.

=head2 symbol

    my $symbol = $set->symbol();

Get the set stock symbol.

=head2 startDate

    $set->startDate($tm); # $tm is a Time::Moment object

Set a start date for a date range limit.  If no argument is passed, retrieves the start date:

    my $tm = $set->startDate();

=head2 endDate

Same as startDate, but gets/sets the end of the period.

=head2 setDateLimit

    $set->setDateLimit($tm1, $tm2);

Same as:

    $set->startDate($tm1);
    $set->endDate($tm2);

=head2 clearDateLimit

    $set->clearDateLimit();

Remove date range restrictions -- established by startDate, endDate, or setDateLimit methods -- from the set.

=head2 transactionDates

    my $transactionDates = $set->transactionDates();

Returns a reference on a array of the Time::Moment objects for every transaction in the set.

=head2 printTransactionDates

    $set->printTransactionDates();

Actually prints to STDOUT the dates returned by the transactionDates method.

=head2 accountSales

    $set->stale() and $set->accountSales();


=head1 AUTHOR

John Everett Refior, C<< <jrefior at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-stockaccount at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-StockAccount>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::StockAccount::Set

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-StockAccount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-StockAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-StockAccount>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-StockAccount/>

=back

=head1 ACKNOWLEDGEMENTS

I would like to thank the Perl Monks for contributing their wisdom when I
posted questions about how to handle date/time and whether there was already a
module capable of doing what I planned.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 John Everett Refior.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
