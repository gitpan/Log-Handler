use strict;
use warnings;
use Test::More tests => 10;
use Log::Handler;
my $MESSAGES = 10;
my $RECEIVED = 0;

$SIG{__WARN__} = sub { forward({message=>shift}) };

sub forward {
    my $m = shift;
    if ($m->{message} =~ /foo/) {
        $RECEIVED++;
    }
}

my $log = Log::Handler->new();
$log->add(forward => { forward_to => \&forward, newline => 1 });

eval { $log->add(foo => 'bar') };
ok($@ ? 1 : 0, 'die on bad params to add()');

# warn and carp
eval { $log->warn('foo') };

# die
eval { $log->error_and_die('foo') };
ok($@ ? 1 : 0, 'die on error_on_die');

eval { $log->err_and_die('foo') };
ok($@ ? 1 : 0, 'die on err_and_die');

eval { $log->critical_and_die('foo') };
ok($@ ? 1 : 0, 'die on critical_and_die');

eval { $log->crit_and_die('foo') };
ok($@ ? 1 : 0, 'die on crit_and_die');

eval { $log->alert_and_die('foo') };
ok($@ ? 1 : 0, 'die on alert_and_die');

eval { $log->emergency_and_die('foo') };
ok($@ ? 1 : 0, 'die on emergency_and_die');

eval { $log->emerg_and_die('foo') };
ok($@ ? 1 : 0, 'die on emerg_and_die');

eval { $log->fatal_and_die('foo') };
ok($@ ? 1 : 0, 'die on fatal_and_die');

# count messages
ok($RECEIVED == $MESSAGES, "count messages ($RECEIVED:$RECEIVED)");
