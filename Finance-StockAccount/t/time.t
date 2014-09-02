use strict;
use warnings;

use Test::More;

use_ok('Time::Moment');

ok(my $tm1 = Time::Moment->from_string('20140827T090807Z'), 'Create tm1');
ok(my $tm2 = Time::Moment->from_string('20140827T090808Z'), 'Create tm2');
is($tm2->epoch() - $tm1->epoch(), 1, 'Tried subtracting tm1 epoch from tm2 epoch');


done_testing();
