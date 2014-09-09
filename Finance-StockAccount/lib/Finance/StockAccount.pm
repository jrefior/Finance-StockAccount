package Finance::StockAccount;

use strict;
use warnings;

use Carp;

use Finance::StockAccount::Set;
use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Stock;

sub new {
    my ($class, $options) = @_;
    my $self = {
        sets                => {},
        skipStocks          => {},
        stats               => {
            stale               => 1,
            startDate           => undef,
            endDate             => undef,
            investment          => undef,
            minInvestment       => undef,
            profit              => undef,
            commissions         => undef,
            regulatoryFees      => undef,
            otherFees           => undef,
            ROI                 => undef,
            meanAnnualROI       => undef,
            meanAnnualProfit    => undef,
        },
        allowZeroPrice      => 0,
    };
    if ($options and exists($options->{allowZeroPrice}) and $options->{allowZeroPrice}) {
        $self->{allowZeroPrice} = 1;
    }
    return bless($self, $class);
}

sub allowZeroPrice {
    my ($self, $allowZeroPrice) = @_;
    if (defined($allowZeroPrice)) {
        $self->{allowZeroPrice} = $allowZeroPrice ? 1 : 0;
        return 1;
    }
    else {
        return $self->{allowZeroPrice};
    }
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

sub getSetFiltered {
    my ($self, $hashKey) = @_;
    if ($self->{skipStocks}{$hashKey}) {
        return undef;
    }
    elsif (exists($self->{sets}{$hashKey})) {
        my $set = $self->{sets}{$hashKey};
        if ($set->stale()) {
            $set->accountSales();
        }
        if ($set->realizationCount() > 0) {
            return $set;
        }
        else {
            return undef;
        }
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
        my $status;
        if ($set) {
            $status = $set->add([$at]);
        }
        else {
            $set = Finance::StockAccount::Set->new([$at]);
            $self->{sets}{$hashKey} = $set;
            $status = $set;
        }
        $status and $self->{stale} = 1;
        return $status;
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
        $added and $self->{stats}{stale} = 1;
        return $added;
    }
    else {
        warn "Method addAccountTransactions requiers a reference to an array of AccountTransaction objects.\n";
        return 0;
    }
}

sub stockTransaction {
    my ($self, $init) = @_;
    my $helpString = q{  Please see 'perldoc Finance::StockAccount'.};
    if (!(exists($init->{tm}) or exists($init->{dateString}))) {
        carp "A date is required to add a stock transaction, using either the 'tm' key or the 'dateString' key.$helpString";
        return 0;
    }
    elsif (!(exists($init->{stock}) or exists($init->{symbol}))) {
        carp "A stock is required to add a transaction, using either the 'stock' key or the 'symbol' key.$helpString";
        return 0;
    }
    elsif (!(exists($init->{action}) and (grep { $_ eq $init->{action} } qw(buy sell short cover)))) {
        carp "To add a transaction, you must specify an action, one of 'buy', 'sell', 'short', or 'cover'.$helpString";
        return 0;
    }
    elsif (!(exists($init->{quantity}) and $init->{quantity} =~ /[0-9]/ and $init->{quantity} > 0)) {
        carp "To add a transaction, you must specify a numeric quantity, and it must be greater than zero.$helpString";
        return 0;
    }
    elsif (!(exists($init->{price}) and $init->{price} =~ /[0-9]/)) {
        carp "To add a transaction, you must specify a price, and it must be numeric.$helpString";
        return 0;
    }
    elsif ($init->{price} <= 0 and !$self->{allowZeroPrice}) {
        carp "To add a transaction, price must be greater than zero.  By default, prices zero or lower are treated as suspect and not included in calculations.\nYou may override this default behavior by setting 'allowZeroPrice' to true.$helpString";
        return 0;
    }
    else {
        if (exists($init->{stock}) and (exists($init->{symbol}) or exists($init->{exchange}))) {
            carp "To add a transaction, you may specify a Finance::StockAccount::Stock object, or a symbol (optionally with an exchange).\nYou need not specify both.  Proceeding on the assumption that the stock object is intentional and the symbol/exchange are accidental...";
            exists($init->{symbol}) and delete($init->{symbol});
            exists($init->{exchange}) and delete($init->{exchange});
        }
        my $at = Finance::StockAccount::AccountTransaction->new($init);
        if ($at) {
            return $self->addToSet($at);
        }
        else {
            carp "Unable to create AccountTransaction object with those parameters.\n";
            return 0;
        }
    }
}

sub skipStocks {
    my ($self, @skipStocks) = @_;
    my $count = 0;
    foreach my $stock (@skipStocks) {
        $self->{skipStocks}{$stock} = 1;
        $count++;
    }
    if ($count) {
        $self->{stats}{stale} = 1;
        return 1;
    }
    else {
        return 0;
    }
}

sub resetSkipStocks {
    my $self = shift;
    if (scalar(keys %{$self->{skipStocks}})) {
        $self->{skipStocks} = {};
        $self->{stats}{stale} = 1;
    }
    return 1;
}

sub staleSets {
    my $self = shift;
    my $stale = 0;
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->getSet($hashKey);
        if ($set) {
            $stale += $set->stale();
        }
    }
    return $stale;
}

sub calculateStats {
    my $self = shift;
    my ($investment, $profit, $commissions, $regulatoryFees, $otherFees) = (0, 0, 0, 0, 0);
    my ($startDate, $endDate);
    my $setCount = 0;
    my @allRealizations = ();
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->getSetFiltered($hashKey);
        if ($set) {
            if ($set->stale()) {
                $set->accountSales();
                next unless $set->success();
            }
            ### Simple Totals
            $investment     += $set->investment();
            $profit         += $set->profit();
            $commissions    += $set->commissions();
            $regulatoryFees += $set->regulatoryFees();
            $otherFees      += $set->otherFees();

            ### Date-Aware Totals
            push(@allRealizations, @{$set->realizations()});

            ### End-Date, Start-Date
            my $setStart = $set->startDate();
            $setStart or die "Didn't get set startDate for hashkey $hashKey\n";
            if (!defined($startDate)) {
                $startDate = $setStart;
            }
            elsif ($setStart < $startDate) {
                $startDate = $setStart;
            }
            my $setEnd   = $set->endDate();
            if (!$endDate) {
                $endDate = $setEnd;
            }
            elsif ($setEnd > $endDate) {
                $endDate = $setEnd;
            }
            $setCount++;
        }
    }
    if ($setCount > 0) {
        if ($investment) {

            my $meanROI = $profit / $investment;
            my $stats = $self->{stats};
            $stats->{investment} = $investment;
            $stats->{profit} = $profit;
            $stats->{commissions} = $commissions;
            $stats->{regulatoryFees} = $regulatoryFees;
            $stats->{otherFees} = $otherFees;
            $stats->{meanROI} = $meanROI;
            $stats->{startDate} = $startDate;
            $stats->{endDate} = $startDate;
            my $secondsInYear = 60 * 60 * 24 * 365.25;
            my $secondsInAccount = $endDate->epoch() - $startDate->epoch();
            my $annualRatio = $secondsInYear / $secondsInAccount;
            $stats->{meanAnnualProfit} = $profit * $annualRatio;

            my @allTransactions = sort { $a->tm() <=> $b->tm() } map { @{$_->acquisitions()}, $_->divestment() } @allRealizations;
            @allRealizations = ();
            my ($total, $max) = (0, 0);
            for (my $x=0; $x<scalar(@allTransactions); $x++) {
                my $transaction = $allTransactions[$x];
                $total += 0 - $transaction->cashEffect();
                $total > $max and $max = $total;
            }
            @allTransactions = ();
            $stats->{minInvestment} = $max;
            my $ROI = $profit / $max;
            $stats->{ROI} = $ROI;
            $stats->{meanAnnualROI} = $ROI * $annualRatio;

            $stats->{stale} = 0;

            return 1;
        }
        else {
            warn "No investment found on which to compute stats.\n";
            return 0;
        }
    }
    else {
        print "No realized gains in stock account.\n";
        return 1;
    }
}

sub getStats {
    my $self = shift;
    if ($self->{stats}{stale} or $self->staleSets()) {
        $self->calculateStats();
    }
    return 1;
}

sub profit {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{profit};
}

sub meanAnnualProfit {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{meanAnnualProfit};
}

sub minInvestment {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{minInvestment};
}

sub ROI {
    my $self = shift;
    $self->getStats();
    my $stats = $self->{stats};
    return $stats->{profit} / $stats->{minInvestment};
}

sub meanAnnualROI {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{meanAnnualROI};
}

sub commissions {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{commissions};
}

sub regulatoryFees {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{regulatoryFees};
}

sub otherFees {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{otherFees};
}


=head1 NAME

Finance::StockAccount - Analyze past transactions in a personal stock account.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Analyze past transactions in a personal stock account.  Get total profit, mean
annual profit, minimum investment that was required to reach that profit, return
on investment compared to that minimum, etc.

Perhaps a little code snippet.

    use Finance::StockAccount;

    my $foo = Finance::StockAccount->new();
    ...

Currently understood transaction types include buy, sell, short, and cover.

Accounting is done by what I call the Greatest Realized Benefit (GRB) method:
divestments (sales or covers) are processed from oldest to newest, and one or
more prior acquisitions (buys or shorts) are matched with the sale by
availability (meaning not all shares are already tied to another divestment) and
lowest cost of the acquisition.

I looked at the "Analyze" tools in my OptionsXpress online brokerage account
and saw it always used a "Last In, First Out" accounting method, which is
ridiculous and was unacceptable to me so I wrote this software to find out my
actual account performance, the one that matched my primary intention when
trading which was usually to realize as much gain as possible.

Dates are stored as Time::Moment objects, and may be specified either as a
Time::Moment object or one of the string formats natively understood by
Time::Moment.

If you happen to have an OptionsXpress online brokerage account you can import
the whole thing in one go with Finance::StockAccount::Import::OptionsXpress.
(I would like to add more formats, so please donate an export from a brokerage
account to help this along!)

Along the way I tried to create a pure stock transaction class and a pure stock
class, please look at

Finance::StockAccount::Transaction
Finance::StockAccount::Stock

for those.

=head1 METHODS


=head2 new


Constructor, instantiates and returns a new Finance::StockAccount object.
Typically called with no arguments:

    my $sa = Finance::StockAccount->new();

Currently there is only one StockAccount option/setting, which may be passed to
new if desired.  By default, attempts to add a stock transaction with a zero
price to a StockAccount object will be treated as suspect and fail.  I realize
that is personal preference, so it may optionally be overcome by setting
allowZeroPrice, like so:

    my $sa = Finance::StockAccount->new({allowZeroPrice => 1});

This option can also be set via method (see allowZeroPrice method below).


=head2 stockTransaction


This is the intended means of adding transactions to a StockAccount object.
An instantiation hash is passed in.  Here is an example:

    $sa->stockTransaction({
        symbol          => 'TWTR',
        dateString      => '20140708T185304Z',
        action          => 'buy',
        quantity        => 50,
        price           => 37.33,
        commission      => 8.95,
    });

Several pieces of information are required.

B<Required: stock>

For one, there must be a stock.  It may be specified as a symbol string, as
above.  An optional exchange string may be passed in as well:

        symbol          => 'TWTR',
        exchange        => 'NYSE', # optional

Alternatively, a stock object can be created using Finance::StockAccount::Stock
and passed in with the stock key:

    my $stock = Finance::StockAccount::Stock->new({
        symbol          => 'TWTR',
        exchange        => 'NYSE', # optional
    });
    $sa->stockTransaction({
        stock           => $stock,
        ...
    });

The same $stock object could then be used over and over to pass in transactions
on that stock. But even if you use a symbol string each time, they will be
treated as the same stock.  An exchange modifies a stock, so you could have two
stocks with the same symbol traded on two different exchanges and they would be
kept separate inside your StockAccount object. 

B<Required: date>

Second, there must be a date for the transaction.  Dates are necessary for
matching a sale to is prior purchase, or for calculating the mean annual profit
(or loss), for example.  Finance::StockAccount uses the CPAN module
Time::Moment to handle dates.  A date can either be passed in as a string using
the dateString key:

        dateString      => '20140708T185304Z',

or a Time::Moment object can be passed in using the tm key:

    my $tm = Time::Moment->new({ # the same date as the string above
        year        => 2014,
        month       => 7,
        day         => 8,
        hour        => 18,
        minute      => 53,
        second      => 4,
        offset      => 0,
    });
    $sa->stockTransaction({
        symbol          => 'TWTR',
        tm              => $tm,
        ...
    });

If using a string passed in with the dateString key, any string acceptable to
the Time::Moment->from_string method without using the 'lenient' flag will
work.  Please see the perldoc for Time::Moment for more information.

B<Required: action>

=head2 allowZeroPrice

Transactions where the price is zero are treated as suspect by default, and
stockTransaction will not add them to the StockAccount object.  However, there
are some legitimate use cases where one might want them to be included, so you
can set the allowZeroPrice option on the StockAccount object to do that:

    $sa->allowZeroPrice(1); # allow transactions with price == 0
    $sa->allowZeroPrice(0); # disallow transactions with price == 0

or or check the value with the same method and no arguments:

    if ($sa->allowZeroPrice()) {
        ... do something ...
    }

As mentioned above, it can also be set using the new method, described above.

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
