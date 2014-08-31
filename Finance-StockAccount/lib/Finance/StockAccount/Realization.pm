package Finance::StockAccount::Realization;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Acquisition;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        divestment          => undef,
        acquisitions        => [],
        divestmentProceeds  => 0,
        costBasis           => 0,
        realized            => undef,
        roi                 => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub addAcquisition {
    my ($self, $acquisition) = @_;
    push(@{$self->{acquisitions}}, $acquisition);
    $self->{costBasis} -= $acquisition->cashEffect();
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
                    $self->{divestmentProceeds} = $divestment->cashEffect();
                }
                else {
                    $status = 0;
                    warn "Invalid divestment value in Realization intialization hash.\n";
                }
            }
            elsif ($key eq 'acquisitions') {
                my $acquisitions = $init->{$key};
                if (ref($acquisitions) and 'ARRAY' eq ref($acquisitions)) {
                    foreach my $acquisition (@$acquisitions) {
                        $self->addAcquisition($acquisition);
                    }
                }
                else {
                    $status = 0;
                    warn "In Realized init, acquisitions value should be a ref to an array of Acquisition objects.\n";
                }
            }
            else {
                $self->{$key} = $init->{$key};
            }
        }
        else {
            $status = 0;
            warn "Tried to set $key in Realization object, but that's not a known key.\n";
        }
    }
    return $status;
}

sub realize {
    my $self = shift;
    my $costBasis = $self->{costBasis};
    my $realized = $self->{divestmentProceeds} - $costBasis;
    $self->{realized} = $realized;
    $self->{roi} = $realized / $costBasis;
    return 1;
}

sub acquisitionCount {
    my $self = shift;
    return scalar(@{$self->{acquisitions}});
}

sub divestment          { return shift->{divestment};           }
sub divestmentProceeds  { return shift->{divestmentProceeds};   }
sub acquisitions        { return shift->{acquisitions};         }
sub costBasis           { return shift->{costBasis};            }
sub realized            { return shift->{realized};             }
sub roi                 { return shift->{roi};                  }



1;
