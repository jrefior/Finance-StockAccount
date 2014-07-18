package OptionsXpress;

use Exporter 'import';
@EXPORT_OK = qw(new);

use StockTransaction;

#### Expected Fields, tab separated:
# Trade Date	Indicator	Action	Symbol/Desc	Qty	Price	Commission	Net Amount	Gain Loss	
# 0             1           2       3           4   5       6           7           8
my @pattern = qw(date 0 action 2 symbol 3 quantity 4 price 5 commission 6);

sub new {
    my ($class, $file) = @_;
    $file or die "Please pass a file to OptionsXpress->new().\n";
    my $self = {
        file                => $file,
        fh                  => undef,
        headers             => undef,
    };
    bless($self, $class);
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    my $file = $self->{file};
    open my $fh, '<', $file or die "Failed to open $file: $!.\n";
    $self->{fh} = $fh;

    my $hline = <$fh>;
    chomp($hline);
    my @headers = split("\t", $hline);
    pop(@headers);
    scalar(@headers) >= scalar(@pattern)/2 or die "Unexpected number of headers. Header line:\n$hline\n";
    $self->{headers} = \@headers;
    <$fh>;
    return 1;
}

sub nextSt {
    my $self = shift;
    my $fh = $self->{fh};
    if (my $line = <$fh>) {
        chomp($line);
        my @row = split("\t", $line);
        pop(@row);

        my $hash = {};
        for (my $x=0; $x<scalar(@pattern)-1; $x+=2) {
            if (exists($row[$pattern[$x+1]])) {
                $hash->{$pattern[$x]} = $row[$pattern[$x+1]];
            }
        }
        my $st = StockTransaction->new($hash);
        return $st;
    }
    else {
        close($fh) or die "Failed to close file descriptor: $!.\n";
        return 0;
    }
}

1;

