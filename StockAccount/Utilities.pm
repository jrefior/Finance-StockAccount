package StockAccount::Transaction::Utilities;
use Exporter 'import';
@EXPORT_OK = qw(new);

use parent 'StockAccount::Transaction';

use Number::Format;
use DateTime;

sub nf {
    my ($self, $nf) = @_;
    if ($nf) {
        if (ref($nf) and 'Number::Format' eq ref($nf)) {
            $self->{nf} = $nf;
            return 1;
        }
        else {
            warn "Not a valid 'Number::Format' object.\n";
            return 0;
        }
    }
    else {
        my $nf = $self->{nf};
        if ($nf) {
        }
        else {
            $nf = $self->numberFormatNew();
            $self->{nf} = $nf;
        }
        return $nf;
    }
}

