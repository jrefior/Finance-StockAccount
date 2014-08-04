package StockAccount::Transaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use constant BUY        => 0;
use constant SELL       => 1;
use constant SHORT      => 2;
use constant COVER      => 3;

# Shared Number Format Object for efficiency, see documentation below
my $nf;

sub new {
    my ($class, $init) = @_;
    my $self = {

        # 'public' properties
        date                => undef,
        action              => undef,
        symbol              => undef,
        quantity            => undef,
        price               => undef,
        commission          => undef,
        regulatoryFees      => undef,
        importedCost        => undef,
        nf                  => undef,

        # 'private' properties
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub numberFormatNew {
    return Number::Format->new({
        INT_CURR_SYMBOL     => $ENV{ST_CURRENCY_SYMBOL} || '$',
    });
}

sub nf {
    my ($self, $nf) = @_;
    if ($nf) {
        if (ref($nf) and 'Number::Format' eq ref($nf)) {
            $self->{nf} = $nf;
            return 1;
        }
        else {
            warn "Not a valid 'Number::Format' object.\n";
            return 0;
        }
    }
    else {
        my $nf = $self->{nf};
        if ($nf) {
        }
        else {
            $nf = $self->numberFormatNew();
            $self->{nf} = $nf;
        }
        return $nf;
    }
}

sub date {
    my ($self, $dt) = @_;
    if ($dt) {
        $self->{date} = $dt;
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

sub set {
    my ($self, $init) = @_;
    for my $key (keys %$init) {
        if (exists($self->{$key})) {
            my $value = $init->{$key};
            if ($key eq 'date') {
                $self->extractDate($value) or return 0;
            }
            elsif ($key eq 'price') {
                $self->extractPrice($value) or return 0;
            }
            elsif ($key eq 'commission') {
                $self->extractCommission($value) or return 0;
            }
            elsif ($key eq 'symbol') {
                $self->extractSymbol($value) or return 0;
            }
            else {
                $self->{$key} = $init->{$key};
            }
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

sub isSale {
    my $self = shift;
    return $self->{action} eq 'Sell';
}

sub possiblePurchase {
    my $self = shift;
    return (($self->{action} eq 'Buy') && ($self->{quantity} > $self->{accounted})) ? 1 : 0;
}

sub extractPrice {
    my ($self, $priceString) = @_;
    if ($priceString =~ /$pricePattern/) {
        my $price = $1;
        $price =~ s/,//g;
        $self->{price} = $price;
    }
    else {
        warn "Failed to recognize price pattern in string $priceString.\n";
        return 0;
    }
}

sub extractCommission {
    my ($self, $commissionString) = @_;
    if ($commissionString =~ /$pricePattern/) {
        my $commission = $1;
        $commission =~ s/,//g;
        $self->{commission} = $commission;
    }
    else {
        warn "Failed to recognize commission pattern in string $commissionString.\n";
        return 0;
    }
}

sub extractSymbol {
    my ($self, $symbolString) = @_;
    if ($symbolString =~ /$symbolPattern/) {
        $self->{symbol} = $1;
    }
    else {
        warn "Failed to recognize symbol pattern in string $symbolString.\n";
        return 0;
    }
}

sub formatDollars {
    my ($self, $num) = @_;
    my $dollars = sprintf("\$%.2f", $num);
    1 while $dollars =~ s/$commifyPattern/$1,$2/;
    return $dollars;
}

sub printTransaction {
    my $self = shift;
    printf("%6s %10s %-4s %6d %7s\n", $self->{symbol}, $self->{date}, $self->{action}, $self->{quantity}, $self->formatDollars($self->{price}));
    return 1;
}

sub accountedValue {
    my $self = shift;
    my $value = $self->{accounted} * $self->{price};
    if ($self->isSale()) {
        $value -= $self->{commission};
    }
    else {
        $value += $self->{commission};
    }
    return $value;
}

1;

__END__

=pod

=head1 NAME

StockAccount::Transaction

=head1 SYNOPSIS

    my $st = StockAccount::Transaction->new({
        date            => $dt,
        action          => 'sell',
        symbol          => 'FTR',
        quantity        => 42,
        price           => 7.11,
        commission      => 8.95,
        regulatoryFees  => 0.01,
        importedCost    => 289.66,
    });

    my $price = $st->formatDollars($st->price());
    print $price, "\n"; # prints string '$7.11'
    my $dt = $st->date(); # Perl DateTime module object.

=head1 PROPERTIES

These are the public properties of a StockAccount::Transaction object:

    date                # DateTime object.  See http://datetime.perl.org/wiki/datetime/dashboard and discussion below.
    action              # One of 'buy', 'sell', 'short', 'cover'.
    symbol              # Vernacular stock symbol string, e.g. 'AAPL', 'QQQ', or 'VZ'.
    exchange            # Optional specification of stock exchange to be associate with symbol, e.g. 'NASDAQ'.
    quantity            # How many shares were bought or sold, e.g. 100 or 5.
    price               # Numeric representation of price, e.g. 4.65 instead of the string '$4.65'.
    commission          # Numeric representation of commission in same currency, e.g. 8.95 instead of the string '$8.95'.
    regulatoryFees      # Numeric representation of the regulatory fees, see section on "Regulatory Fees" below.
    importedCost        # Numeric representation of the total expenditure, if a purchase, plus commission and regulatory fees;
                        #  or revenue, if a sale, less commission and regulatory fees, as imported.  Can be used to check for
                        #  accounting discrepancies.  Perhaps not the best named property - any suggestions for a better name?
    nf                  # Perl Number::Format object, usually all objects point to the same one, but you can change that, see
                        #  documentation section on Number::Format.

There are also some private properties of the class used internally for
efficiency or other considerations, they are not documented here.

Any public property can be instantiated in the C<new> method, set with a method
matching the name of the property, such as C<$st->date($dt)>, or set with the
C<set> method, e.g. C<$st->set({date => $dt})>, as specified further in the
method description below.

Public properties can be retrieved by the C<get> method with a string naming the
property, e.g. C<$st->get('price')>.

All properties can also be read or written directly with a hash dereference.
Some people don't consider this good object-oriented practice, but I won't stop
you if that's what you want to do.  E.g. C<$st->{date} = $dt> or
C<$st->{price}>.

=head1 CONFIGURATION

The following optional environment variables are read and used if set.

    ST_CURRENCY_SYMBOL          # Defaults to '$' if this is not set.

=head1 NUMBER::FORMAT AND DATETIME LIBRARIES

This StockAccount::Transaction Perl module is dependent on:

 Number::Format     To format numbers into currency strings

I started with using '$' and rounding to two decimal places, but then I
realized that might not be very helpful for people in other countries.  Also
the problems of how to format the currency (e.g. 'USD' versus '$'), how to
format negative numbers in the currency string, how to specify a currency,
etc., have all been handled by Number::Format, so it seemed better to reused
that code.

 DateTime           
 
In development I quickly ran into the problem of what date format(s) to accept,
what to print, how the user can specify a different format, etc.  The Perl
DateTime library has become pretty standard for dealing with those issues, and
there seemed no good reason for me to duplicate that code.  So instead I store
a DateTime object in the "dt" property.

=head1 REGULATORY FEES

In the United States the Securities and Exchange Commission imposes regulatory
fees on stock brokers or dealers.  Instead of paying these with their profits,
these for-profit companies often pass these fees onto their customers directly.
The C<regulatoryFees> property could be used for similar purposes in other
jurisdictions.

See http://www.sec.gov/answers/sec31.htm for more information.

=cut
