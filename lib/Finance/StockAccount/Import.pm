





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
