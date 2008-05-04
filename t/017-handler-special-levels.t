use strict;
use warnings;
use Test::More tests => 22;
use Log::Handler;

my $MESSAGES = 14;
my $RECEIVED = 0;
my %LEVELS   = (
    DEBUG     =>  1,
    INFO      =>  1,
    NOTICE    =>  1,
    WARNING   =>  3,
    ERROR     =>  2,
    CRITICAL  =>  2,
    ALERT     =>  1,
    EMERGENCY =>  2,
    FATAL     =>  1,
);
my @LEVELS = (qw/
    debug
    info
    notice
    warning
    error
    err
    critical
    crit
    alert
    emergency
    emerg
    fatal
/);

$SIG{__WARN__} = sub { forward({message=> 'WARNING '.shift}) };

sub forward {
    my $m = shift;
    if ($m->{message} =~ /([A-Z]+) foo/) {
        my $level = $1;
        if (exists $LEVELS{$level}) {
            $LEVELS{$level}--;
        }
        $RECEIVED++;
    }
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        maxlevel => 'debug',
        forward_to => \&forward,
        message_layout => '%L %m',
    }
);

# warn
$log->warn('foo');

# die
foreach my $level (@LEVELS) {
    my $ul = uc($level);
    eval { $log->die($level => 'foo') };
    ok($@ =~ /foo/, "test die $level");
}

# count messages
ok($RECEIVED == $MESSAGES, "count messages ($RECEIVED:$MESSAGES)");

# got all messages?
while ( my ($level, $count) = each %LEVELS ) {
    ok($count == 0, "test level $level ($count)");
}
