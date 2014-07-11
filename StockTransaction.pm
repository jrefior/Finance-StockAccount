package StockTransaction;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

my $datePattern = '^\s*([0-9]{2}\/[0-9]{2}\/[0-9]{4})\s*$';

sub new {
    my ($class, $init) = @_;
    my $self = {
        date        => undef, 
        action      => undef, 
        symbol      => undef, 
        quantity    => undef, 
        price       => undef, 
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

sub set {
    my ($self, $init) = @_;
    for my $key (keys %$init) {
        if (exists($self->{$key})) {
            my $value = $init->{$key};
            if ($key eq 'date') {
                $self->extractDate($value) or return 0;
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
    return sprintf("$%.2f", shift->{price});
}

1;
