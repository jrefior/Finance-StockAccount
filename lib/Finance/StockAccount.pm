package StockAccount;

use strict;
use warnings;



sub possiblePurchase {
    my $self = shift;
    return (($self->{action} eq 'Buy') && ($self->{quantity} > $self->{accounted})) ? 1 : 0;
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
