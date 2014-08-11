package Finance::StockAccount::Import::OptionsXpress;

use Exporter 'import';
@EXPORT_OK = qw(new);

use parent 'Finance::StockAccount::Import';


#### Expected Fields, tab separated:
# Symbol, Description, Action, Quantity, Price, Commission, Reg Fees, Date, TransactionID, Order Number, Transaction Type ID, Total Cost 
# 0       1            2       3         4      5           6         7     8              9             10                   11
my @pattern = qw(symbol 0 action 2 quantity 3 price 4 commission 5 regulatoryFees 6 date 7 totalCost 11);

sub new {
    my ($class, $file) = @_;
    my $self = SUPER::new($class, $file);
    $self->{pattern} = \@pattern;
    $self->{headers} = undef;
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
    scalar(@headers) >= scalar(@{$self->{pattern})/2 or die "Unexpected number of headers. Header line:\n$hline\n";
    $self->{headers} = \@headers;
    my $blankLine = <$fh>;
    $blankLine =~ /\w/ and warn "Expected blank line after header line.  May have inadvertantly skipped first transaction...\n";
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

