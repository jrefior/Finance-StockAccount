package StockAccount::Transaction::Utilities;
use Exporter 'import';
@EXPORT_OK = qw(new);

use parent 'StockAccount::Transaction';

use Number::Format;
use DateTime;

sub new {
    my ($class, $init) = @_;
    my $self = {
        nf              => undef,
    };
    bless($self, $class);
    $init and $self->init($init);
    return $self;
}

sub numberFormatNew {
    return Number::Format->new({
        INT_CURR_SYMBOL     => $ENV{ST_CURRENCY_SYMBOL} || '$',
    });
}

sub formatDollars {
    my ($self, $num) = @_;
    my $dollars = sprintf("\$%.2f", $num);
    1 while $dollars =~ s/$commifyPattern/$1,$2/;
    return $dollars;
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

1;

__END__

=pod

=head1 NAME

Finance::StockAccount::Utilities

=head1 SYNOPSIS

=head2 PROPERTIES

    nf                  # Perl Number::Format object, usually all objects point to the same one, but you can change that, see
                        #  documentation section on Number::Format.


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

=cut
