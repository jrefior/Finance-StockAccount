package Finance::StockAccount::Transaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use Finance::StockAccount::Stock;

use strict;
use warnings;

use constant BUY        => 0;
use constant SELL       => 1;
use constant SHORT      => 2;
use constant COVER      => 3;

sub new {
    my ($class, $init) = @_;
    my $self = {
        # 'public' properties
        date                => undef,
        action              => undef,
        stock               => undef,
        quantity            => undef,
        price               => undef,
        commission          => undef,
        regulatoryFees      => undef,
        cashEffect          => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub date {
    my ($self, $date) = @_;
    if ($date) {
        $self->{date} = $date;
        return 1;
    }
    else {
        return $self->{date};
    }
}

sub action {
    my ($self, $action) = @_;
    if ($action) {
        $self->{action} = $action;
        return 1;
    }
    else {
        return $self->{action};
    }
}

sub stock {
    my ($self, $stock) = @_;
    if ($stock) {
        if (ref($stock) and 'Finance::StockAccount::Stock' eq ref($stock)) {
            $self->{stock} = $stock;
            return 1;
        }
        else {
            warn "$stock is not a recognized Finance::StockAccount::Stock object.\n";
            return 0;
        }
    }
    else {
        return $self->{stock};
    }
}

sub symbol {
    my ($self, $symbol) = @_;
    my $stock = $self->{stock};
    return $stock->symbol($symbol);
}

sub exchange {
    my ($self, $exchange) = @_;
    my $stock = $self->{stock};
    return $stock->exchange($exchange);
}

sub quantity {
    my ($self, $quantity) = @_;
    if ($quantity) {
        $self->{quantity} = $quantity;
        return 1;
    }
    else {
        return $self->{quantity};
    }
}

sub price {
    my ($self, $price) = @_;
    if ($price) {
        $self->{price} = $price;
        return 1;
    }
    else {
        return $self->{price};
    }
}

sub commission {
    my ($self, $commission) = @_;
    if ($commission) {
        $self->{commission} = $commission;
        return 1;
    }
    else {
        return $self->{commission};
    }
}

sub regulatoryFees {
    my ($self, $regulatoryFees) = @_;
    if ($regulatoryFees) {
        $self->{regulatoryFees} = $regulatoryFees;
        return 1;
    }
    else {
        return $self->{regulatoryFees};
    }
}

sub cashEffect {
    my ($self, $cashEffect) = @_;
    if ($cashEffect) {
        $self->{cashEffect} = $cashEffect;
        return 1;
    }
    else {
        return $self->{cashEffect};
    }
}

sub set {
    my ($self, $init) = @_;
    for my $key (keys %$init) {
        if (exists($self->{$key})) {
            $self->{$key} = $init->{$key};
            return 1;
        }
        else {
            warn "Tried to set $key in StockAccount::Transaction object, but that's not a known key.\n";
            return 0;
        }
    }
}

sub get {
    my ($self, $key) = @_;
    if ($key and exists($self->{$key})) {
        return $self->{$key};
    }
    else {
        warn "Tried to get key from StockAccount::Transaction object, but that's not a known key.\n";
        return 0;
    }
}

sub buy {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = BUY;
    }
    else {
        return $self->{action} == BUY;
    }
}

sub sell {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = SELL;
    }
    else {
        return $self->{action} == SELL;
    }
}

sub short {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = SHORT;
    }
    else {
        return $self->{action} == SHORT;
    }
}

sub cover {
    my ($self, $assertion) = @_;
    if ($assertion) {
        $self->{action} = COVER;
    }
    else {
        return $self->{action} == COVER;
    }
}

sub actionString {
    my $self = shift;
    if ($self->buy()) {
        return 'buy';
    }
    elsif ($self->sell()) {
        return 'sell';
    }
    elsif ($self->short()) {
        return 'short';
    }
    elsif ($self->cover()) {
        return 'cover';
    }
    else {
        return '';
    }
}

sub printTransaction {
    my $self = shift;
    printf("%6s %10s %-4s %6d %6d %6d %6d %8d\n", $self->symbol(), $self->{date}, $self->actionString, $self->{quantity}, $self->{price}, $self->{commission}, $self->{regulatoryFees}, $self->{cashEffect});
    return 1;
}


1;

__END__

=pod

=head1 NAME

Finance::StockAccount::Transaction

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
    cashEffect          # Numeric representation of the total effect of the transaction on your cash balance sheet.  For example,
                        #  with a 'buy' result would be 0 - (price * quantity + commission + regulatoryFees). Intended to be
                        #  added to your cash balance directly to find the new cash balance.

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
