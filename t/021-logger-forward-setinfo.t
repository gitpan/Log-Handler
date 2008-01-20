use strict;
use warnings;
use Test::More tests => 10;
use File::Spec;
use Log::Handler::Logger;

my $CHECKED = 0;

sub check_struct {
    $CHECKED = 1;
    my $params = shift;
    if (ref($params) ne 'HASH') {
        die "not a hash ref";
    }
    foreach my $name (qw(level pid timestamp time progname caller hostname message)) {
        my $ret = defined $params->{$name} ? 1 : 0;
        ok($ret, "checking param $name");
    }
}

my $log = Log::Handler::Logger->new(
    forward => {
        forward_to => [ \&check_struct ],
        maxlevel   => 'debug',
        minlevel   => 'debug',
        prefix     => '',
        setinfo    => [ qw/%L %T %P %H %C %p %t/ ],
    }
);

ok(1, 'new');

$log->write('DEBUG', 'foo');

ok($CHECKED, "call check_struct()");
