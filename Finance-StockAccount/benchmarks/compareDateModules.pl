#!/bin/env perl

use strict;
use warnings;

use Time::HiRes;
use Benchmark qw(cmpthese :hireswallclock);

sub tStart {
    return [Time::HiRes::gettimeofday()];
}

sub tEnd {
    my $t0 = shift;
    return Time::HiRes::tv_interval($t0);
}


### Loading Modules
sub timeLoad {
    my $modules = shift;
    for (my $x=0; $x<scalar(@$modules); $x+=2) {
        my $module = $modules->[$x];
        my $t0 = tStart();
        my $code = $modules->[$x+1];
        eval "$code";
        print $module, '    ', tEnd($t0), "\n";
    }
}

my $modules = [
    'Time::Moment          ',   'use Time::Moment',
    'Time::Piece           ',   'use Time::Piece',
    'DateTime              ',   'use DateTime',
    'DateTime::Format::CLDR',   'use DateTime::Format::CLDR',
];

timeLoad($modules);


### Creating Parsers
sub newCldr {
    my $dateFormat = "M/d/yy";
    my $t0 = tStart();
    my $cldr = DateTime::Format::CLDR->new(
        pattern     => $dateFormat,
        locale      => 'US_en',
        time_zone   => 'UTC',
    );
    my $elapsed = tEnd($t0);
    print "CLDR: $elapsed\n";
    return $cldr;
}

print "Creating parsers:\n";
my $cldr = newCldr();


### Parsing Date Strings
my $dateString = "1/31/12";
my $tmDateString = "20120131T000000Z";
my ($dt1, $tp1, $tm1);
Benchmark::timethese(80000, {
    'DateTime    '      => sub { $dt1 = $cldr->parse_datetime($dateString) },
    'Time::Piece '      => sub { $tp1 = Time::Piece->strptime($dateString, "%D") },
    'Time::Moment'      => sub { $tm1 = Time::Moment->from_string($tmDateString) },
});

__END__

Results on my test machine:

Loading the module:




