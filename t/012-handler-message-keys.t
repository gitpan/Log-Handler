use strict;
use warnings;
use Test::More tests => 11;
use Log::Handler;

my $CHECKED = 0;

sub check_struct {
    $CHECKED = 1;
    my $params = shift;
    if (ref($params) ne 'HASH') {
        die "not a hash ref";
    }
    foreach my $name (qw(level pid time date mtime progname caller hostname message)) {
        my $ret = defined $params->{$name} ? 1 : 0;
        ok($ret, "checking param $name");
    }
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        forward_to     => \&check_struct,
        maxlevel       => 'debug',
        minlevel       => 'debug',
        message_layout => '',
        message_keys   => [ qw/%L %T %D %P %H %C %p %t/ ],
    }
);

ok(1, 'new');

$log->debug('foo');

ok($CHECKED, "call check_struct()");
