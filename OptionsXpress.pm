package OptionsXPress;

use Exporter 'import';
@EXPORT_OK = qw(new);

use StockTransaction;

#### Expected Fields, tab separated:
# Trade Date	Indicator	Action	Symbol/Desc	Qty	Price	Commission	Net Amount	Gain Loss	
# 0             1           2       3           4   5       6           7           8
my @pattern = qw(date 0 action 2 symbol 3 quantity 4 price 5);

sub new {
    my ($class, $file) = @_;
    my $self = {
        file                => $file,
        fh                  => undef,
    };
    bless($self, $class);
    $self->init();
    return $self;
}
