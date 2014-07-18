package TransactionSet;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use StockTransaction;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stBySymbol      => undef, # hash of arrays, e.g. {'AAPL' => [$st1, $st2, ...], ...}
        sorted          => 0,
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub add {
    my ($self, $transactions) = @_;
    ($transactions and 'ARRAY' eq ref($transactions))
        or die "TransactionSet->add([\$st1, \$st2, \$st3, ...]) ... method requires a reference to a list of st objects.\n";
    foreach my $st (@$transactions) {
       'StockTransaction' eq ref($st) or die "Not a valid st object.\n";
       push(@{$self->{stBySymbol}{$st->{symbol}}}, $st);
    }
    $self->{sorted} = 0;
}

sub cmpStDate {
    my ($self, $st1, $st2) = @_;
    my ($m1, $d1, $y1) = $st1->dateMDY();
    my ($m2, $d2, $y2) = $st2->dateMDY();
    if ($y1 == $y2) {
        if ($m1 == $m2) {
            if ($d1 == $d2) {
                return 0;
            }
            elsif ($d1 > $d2) {
                return 1;
            }
            else {
                return -1;
            }
        }
        elsif ($m1 > $m2) {
            return 1;
        }
        else {
            return -1;
        }
    }
    elsif ($y1 > $y2) {
        return 1;
    }
    else {
        return -1;
    }
}

sub sortSt {
    my $self = shift;
    foreach my $symbol (keys %{$self->{stBySymbol}}) {
        $self->{stBySymbol}{$symbol} = [sort { $self->cmpStDate($a, $b) } @{$self->{stBySymbol}{$symbol}}];
    }
    $self->{sorted} = 1;
    return 1;
}

1;
