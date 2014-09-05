package Finance::StockAccount::Realization;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use Time::Moment;

use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Acquisition;

sub new {
    my ($class, $init) = @_;
    my $self = {
        stock               => undef,
        divestment          => undef,
        acquisitions        => [],
        divestedShares      => 0,
        realized            => undef,
        roi                 => undef,
    };
    bless($self, $class);
    $init and $self->set($init);
    return $self;
}

sub addAcquisition {
    my ($self, $acquisition, $shares) = @_;
    push(@{$self->{acquisitions}}, $acquisition);
    $self->{divestedShares} += $shares;
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

sub costBasis {
    my $self = shift;
    my $costBasis = 0;
    foreach my $acquisition (@{$self->{acquisitions}}) {
        $costBasis -= $acquisition->cashEffect();
    }
    return $costBasis;
}

sub proceeds {
    my $self = shift;
    my $divestment = $self->{divestment};
    my $shares = $self->{divestedShares};
    my $ratio = $shares / $divestment->quantity();
    my $feesAndCommissions = $ratio * $divestment->feesAndCommissions();
    return $divestment->price() * $shares - $feesAndCommissions;
}

sub realize {
    my $self = shift;
    my $costBasis = $self->costBasis();
    my $proceeds = $self->proceeds();
    my $realized = $proceeds - $costBasis;
    $self->{realized} = $realized;
    if ($costBasis) {
        $self->{roi} = $realized / $costBasis;
        return 1;
    }
    else {
        warn "Realize method finds no cost basis upon which to compute ROI.\n";
        return 0;
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
sub realized            { return shift->{realized};             }
sub roi                 { return shift->{roi};                  }



1;
