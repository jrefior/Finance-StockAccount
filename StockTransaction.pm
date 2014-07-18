package StockTransaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use constant BUY  => 1;
use constant SELL => 0;
my $datePattern    = '^\s*([0-9]{2}\/[0-9]{2}\/[0-9]{4})\s*$';
my $pricePattern   = '^\s*\$((?:[0-9]{1,3},)*[0-9]+(?:\.[0-9]+)?)\s*$';
my $commifyPattern = '^(-?\$[0-9]+)([0-9]{3})';
my $symbolPattern  = '^\s*(\w+)\s*';

sub new {
    my ($class, $init) = @_;
    my $self = {
        date        => undef, 
        action      => undef, 
        symbol      => undef, 
        quantity    => undef, 
        price       => undef, 
        commission  => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub extractDate {
    my ($self, $dateString) = @_;
    if ($dateString =~ /$datePattern/) {
        $self->{date} = $1;
    }
    else {
        warn "Failed to recognize date pattern in string $dateString.\n";
        return 0;
    }
}

sub dateMDY {
    my $self = shift;
    return split('/', $self->{date});
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
        }
        else {
            warn "Tried to set $key, but that's not a known key.\n";
        }
    }
    return 1;
}

sub formatDollars {
    my ($self, $num) = @_;
    my $dollars = sprintf("\$%.2f", $num);
    1 while $dollars =~ s/$commifyPattern/$1,$2/;
    return $dollars;
}

1;
