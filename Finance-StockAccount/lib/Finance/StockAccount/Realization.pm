package Finance::StockAccount::Realization;

use strict;
use warnings;

use Time::Moment;
use Carp;

use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Acquisition;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        divestment          => undef,
        acquisitions        => [],
        costBasis           => 0,
        proceeds            => 0,
        realized            => 0,
        commissions         => 0,
        regulatoryFees      => 0,
        otherFees           => 0,
        roi                 => 0,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub addAcquisition {
    my ($self, $acquisition, $dateLimitPortion) = @_;
    if (!defined($dateLimitPortion)) {
        $dateLimitPortion = 1; # Assume no date limit restriction if none specified, i.e., none by default
    }
    my $shares = $acquisition->shares();
    my $divestment = $self->{divestment};
    my $divQuantity = $divestment->quantity();
    my $divestedPortion;
    if ($divQuantity) {
        $divestedPortion = $shares / $divQuantity;
    }
    else {
        croak "No shares divested in transaction, cannot proceed with realization.";
    }

    my $divCommission     += $divestedPortion * $divestment->commission();
    my $divRegulatoryFees += $divestedPortion * $divestment->regulatoryFees();
    my $divOtherFees      += $divestedPortion * $divestment->otherFees();

    my $costBasis = 0 - $dateLimitPortion * $acquisition->cashEffect();
    my $proceeds  = $dateLimitPortion * $divestedPortion * $divestment->cashEffect();
    $self->{costBasis}      += $costBasis;
    $self->{proceeds}       += $proceeds;
    $self->{realized}       += $proceeds - $costBasis;
    $self->{commissions}    += $dateLimitPortion * ($acquisition->commission()     + $divCommission    );
    $self->{regulatoryFees} += $dateLimitPortion * ($acquisition->regulatoryFees() + $divRegulatoryFees);
    $self->{otherFees}      += $dateLimitPortion * ($acquisition->otherFees()      + $divOtherFees     );

    push(@{$self->{acquisitions}}, $acquisition);
    return 1;
}

sub set {
    my ($self, $init) = @_;
    my $status = 1;
    foreach my $key (keys %{$init}) {
        if (exists($self->{$key})) {
            if ($key eq 'divestment') {
                my $divestment = $init->{$key};
                if ($divestment and ref($divestment)) {
                    $self->{divestment} = $divestment;
                }
                else {
                    $status = 0;
                    warn "Invalid divestment value in Realization intialization hash.\n";
                }
            }
            elsif ($key eq 'stock') {
                $self->{$key} = $init->{$key};
            }
            else {
                $status = 0;
                warn "Unable to initialize Realization object with $key parameter.\n";
            }
        }
        else {
            $status = 0;
            warn "Tried to set $key in Realization object, but that's not a known key.\n";
        }
    }
    return $status;
}

sub roi {
    my $self = shift;
    my $costBasis = $self->{costBasis};
    if ($costBasis) {
        return $self->{realized} / $costBasis;
    }
    else {
        warn "Realize method finds no cost basis upon which to compute ROI.\n";
        return undef;
    }
}

sub acquisitionCount {
    my $self = shift;
    return scalar(@{$self->{acquisitions}});
}

sub startDate {
    my $self = shift;
    my $startDate;
    foreach my $acquisition (@{$self->{acquisitions}}) {
        if (!$startDate) {
            $startDate = $acquisition->tm();
        }
        else {
            my $tm = $acquisition->tm();
            if ($tm < $startDate) {
                $startDate = $tm;
            }
        }
    }
    return $startDate;
}

sub endDate {
    my $self = shift;
    my $divestment = $self->{divestment};
    return $divestment->tm();
}


sub divestment          { return shift->{divestment};           }
sub acquisitions        { return shift->{acquisitions};         }
sub costBasis           { return shift->{costBasis};            }
sub proceeds            { return shift->{proceeds};             }
sub realized            { return shift->{realized};             }
sub commissions         { return shift->{commissions};          }
sub regulatoryFees      { return shift->{regulatoryFees};       }
sub otherFees           { return shift->{otherFees};            }



1;
