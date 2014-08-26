package Finance::StockAccount::AccountTransaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use parent 'Finance::StockAccount::Transaction';

use strict;
use warnings;

sub new {
    my ($class, $init) = @_;
    my $self = $class->SUPER::new($init);
    $self->{accounted} = 0;
    return $self;
}

sub accounted {
    my ($self, $accounted) = @_;
    if ($accounted) {
        $self->{accounted} = $accounted;
        return 1;
    }
    else {
        return $self->{accounted};
    }
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

sub possiblePurchase {
    my ($self, $actionString) = @_;
    if (    (($actionString eq 'sale' and $self->buy()) or
             ($actionString eq 'cover' and $self->short()))
            and $self->available()) {
        return 1;
    }
    else {
        return 0;
    }
}



1;

__END__

=pod

=head1 NAME

Finance::StockAccount::AccountTransaction

=head1 SYNOPSIS

    my $ftr = Finance::StockAccount::Stock->new({
        symbol          => 'FTR',
        exchange        => 'NASDAQ',
    });

    my $st = Finance::StockAccount::Transaction->new({
        date            => $dt,
        action          => Finance::StockAccount::Transaction::SELL,
        stock           => $ftr,
        quantity        => 42,
        price           => 7.11,
        commission      => 8.95,
        regulatoryFees  => 0.01,
    });

    print $st->price(), "\n"; # prints number 7.11

=head1 PROPERTIES

These are the public properties of a StockAccount::Transaction object:

    date                # 'presumed' DateTime object.  See http://datetime.perl.org/wiki/datetime/dashboard and discussion below.
    action              # One of module constants BUY, SELL, SHORT, COVER
    stock               # A Finance::StockAccount::Stock object
    quantity            # How many shares were bought or sold, e.g. 100 or 5.
    price               # Numeric representation of price, e.g. 4.65 instead of the string '$4.65'.
    commission          # Numeric representation of commission in same currency, e.g. 8.95 instead of the string '$8.95'.
    regulatoryFees      # Numeric representation of the regulatory fees, see section on "Regulatory Fees" below.
    otherFees           # Numeric aggregation of any other fees not included in commission and regulatory fees.

Any public property can be instantiated in the C<new> method, set with a method
matching the name of the property, such as C<$st->date($dt)>, or set with the
C<set> method, e.g. C<$st->set({date => $dt})>, as specified further in the
method description below.

Public properties can also be retrieved by the same method matching the name of
the property when no parameter is passed, e.g. C<$st->date()>.  Or by the
C<get> method with a string naming the property, e.g. C<$st->get('price')>.

All properties can also be read or written directly with a hash dereference.
Some people don't consider this good object-oriented practice, but I won't stop
you if that's what you want to do.  E.g. C<$st->{date} = $dt> or
C<$st->{price}>.

=head1 REGULATORY FEES

In the United States the Securities and Exchange Commission imposes regulatory
fees on stock brokers or dealers.  Instead of paying these with their profits,
these for-profit companies often pass these fees onto their customers directly.
The C<regulatoryFees> property could be used for similar purposes in other
jurisdictions.

See http://www.sec.gov/answers/sec31.htm for more information.

=cut
