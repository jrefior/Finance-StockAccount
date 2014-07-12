package TransactionSet;
use Exporter 'import';
@EXPORT_OK = qw(new);

use strict;
use warnings;

use StockTransaction;

sub new {
    my ($class, $init) = @_;
    my $self = {
        #    symbols         => undef,
        stBySymbol      => undef,
    };
    bless($self, $class);
    $init and $self->add($init);
    return $self;
}

sub add {
    my ($self, $transactions) = @_;
    ($transactions and 'ARRAY' eq ref($transactions))
        or die "TransactionSet->add([$st1, $st2, $st3, ...]) ... method requires a reference to a list of st objects.\n";
    foreach my $st (@$transactions) {
        'StockTransaction' eq ref($st) or die "Not a valid st object.\n";






