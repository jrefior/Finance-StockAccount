package Finance::StockAccount::Acquisition;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use Finance::StockAccount::AccountTransaction;


sub new {
    my ($class, $at, $shares) = @_;
    my $self = {
        at                  => undef,
        shares              => 0,
        cashEffect          => undef,
        feesAndCommissions  => undef,
    };
    bless($self, $class);
    $self->init($at, $shares);
    return $self;
}

sub at {
    my ($self, $at) = @_;
    if ($at) {
        if (ref($at) and ($at->buy() or $at->short())) {
            $self->{at} = $at;
            return 1;
        }
        else {
            die "Acquisition requires a valid AccountTransaction object of type buy or short.";
            return 0;
        }
    }
    else {
        return $self->{at};
    }
}

sub cashEffect         { return shift->{cashEffect};         }
sub feesAndCommissions { return shift->{feesAndCommissions}; }
sub shares             { return shift->{shares};             }

sub tm {
    my $self = shift;
    my $at = $self->{at};
    return $at->tm();
}

sub proportion {
    my $self = shift;
    my $shares = $self->{shares};
    my $at = $self->{at};
    my $quantity = $at->quantity();
    return $shares / $quantity;
}

sub compute {
    my $self = shift;
    my $proportion = $self->proportion();
    my $at = $self->at();
    $self->{cashEffect} = $at->cashEffect() * $proportion;
    $self->{feesAndCommissions} = $at->feesAndCommissions() * $proportion;
    return 1;
}

sub init {
    my ($self, $at, $shares) = @_;
    if (!($at and $shares)) {
        die "Acquisition->new constructor requires \$at (AccountTransaction) and shares count parameters.\n";
    }
    if ($shares =~ /^[0-9]+$/ and $shares > 0) {
        $self->at($at);
        $self->{shares} = $shares;
        $self->compute();
        return 1;
    }
    else {
        die "Acquisition::Init requires numeric positive shares value, got $shares.\n";
        return 0;
    }
}




1;
