package Finance::StockAccount::Stock;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

sub new {
    my ($class, $init) = @_;
    my $self = {
        symbol              => undef,
        exchange            => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub set {
    my ($self, $init) = @_;
    for my $key (keys %$init) {
        if (exists($self->{$key})) {
            $self->{$key} = $init->{$key};
            return 1;
        }
        else {
            warn "Tried to set $key in Finance::StockAccount::Stock object, but that's not a known key.\n";
            return 0;
        }
    }
}

sub symbol {
    my ($self, $symbol) = @_;
    if ($symbol) {
        $self->{symbol} = $symbol;
        return 1;
    }
    else {
        return $self->{symbol};
    }
}

sub exchange {
    my ($self, $exchange) = @_;
    if ($exchange) {
        $self->{exchange} = $exchange;
        return 1;
    }
    else {
        return $self->{exchange};
    }
}

1;

__END__



    symbol              # Vernacular stock symbol string, e.g. 'AAPL', 'QQQ', or 'VZ'.
    exchange            # Optional specification of stock exchange to be associate with symbol, e.g. 'NASDAQ'.
