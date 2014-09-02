package Finance::StockAccount;

use strict;
use warnings;

use Finance::StockAccount::Set;
use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Stock;

sub new {
    my ($class, $init) = @_;
    my $self = {
        sets                => {},
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub getSet {
    my ($self, $hashKey) = @_;
    if (exists($self->{sets}{$hashKey})) {
        return $self->{sets}{$hashKey};
    }
    else {
        return undef;
    }
}

sub addToSet {
    my ($self, $at) = @_;
    if (ref($at) and ref($at) eq 'Finance::StockAccount::AccountTransaction') {
        my $hashKey = $at->hashKey();
        my $set = $self->getSet($hashKey);
        if ($set) {
            return $set->add([$at]);
        }
        else {
            $set = Finance::StockAccount::Set->new([$at]);
            $self->{sets}{$hashKey} = $set;
            return $set;
        }
    }
    else {
        warn "Method addToSet requires a valid AccountTransaction object.\n";
        return 0;
    }
}

sub addAccountTransactions {
    my ($self, $accountTransactions) = @_;
    if (ref($accountTransactions) and ref($accountTransactions) eq 'ARRAY') {
        my $added = 0;
        foreach my $at (@$accountTransactions) {
            $self->addToSet($at) and $added++;
        }
        return $added;
    }
    else {
        warn "Method addAccountTransactions requiers a reference to an array of AccountTransaction objects.\n";
        return 0;
    }
}

sub stockTransaction {
    my ($self, $init) = @_;
    my $at = Finance::StockAccount::AccountTransaction->new($init);
    if ($at) {
        return $self->addToSet($at);
    }
    else {
        warn "Unable to create AccountTransaction object with those parameters.\n";
        return 0;
    }
}

sub stale {
    my $self = shift;
    my $stale = 0;
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->{sets}{$hashKey};
        $stale += $set->stale();
    }
    return $stale;
}

sub ROI {
    my $self = shift;
    my ($investment, $profit) = (0, 0);
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->{sets}{$hashKey};
        if ($set->stale()) {
            $set->accountSales();
        }
        $investment += $set->investment();
        $profit     += $set->profit();
    }
    if ($investment) {
        return $profit / $investment;
    }
    else {
        warn "No investment found on which to compute ROI.\n";
        return 0;
    }
}

sub meanAnnualROI {
    my $self = shift;
    my ($investment, $profit) = (0, 0);
    my ($startDate, $endDate);
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->{sets}{$hashKey};
        if ($set->stale()) {
            $set->accountSales();
        }
        $investment += $set->investment();
        $profit     += $set->profit();
        my $setStart = $set->startDate();
        if (!$startDate) {
            $startDate = $setStart;
        }
        elsif ($setStart < $startDate) {
            $startDate = $setStart;
        }
        my $setEnd   = $set->endDate();
        if (!$endDate) {
            $endDate = $setEnd;
        }
        elsif ($setEnd < $endDate) {
            $endDate = $setEnd;
        }
    }
    if ($investment) {
        my $secondsInYear = 60 * 60 * 24 * 365.25;
        my $secondsInAccount = $endDate->epoch() - $startDate->epoch();
        warn "Seconds in account: $secondsInAccount - as days: ", $secondsInAccount / 60 / 60 / 24;
        return ($profit / $investment) * ($secondsInYear / $secondsInAccount);
    }
    else {
        warn "No investment found on which to compute ROI.\n";
        return 0;
    }
}




=head1 NAME

Finance::StockAccount - The great new Finance::StockAccount!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Finance::StockAccount;

    my $foo = Finance::StockAccount->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

John Everett Refior, C<< <jrefior at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-stockaccount at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-StockAccount>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::StockAccount


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


=cut

1; # End of Finance::StockAccount
