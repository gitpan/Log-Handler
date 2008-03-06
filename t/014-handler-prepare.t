use strict;
use warnings;
use Test::More tests => 3;
use Log::Handler;

our $PREPARE_RET   =  0;
our $FORWARD_RET   =  0;
our $MESSAGE_CHECK =  0;
our $MESSAGE       = '';

sub prepare {
    $PREPARE_RET++;
    my $message = shift;
    $message->{message} .= 'bar';
}

sub forward {
    $FORWARD_RET++;
    my $message = shift;
    $MESSAGE_CHECK = $message->{message} eq 'foobar';
    $MESSAGE = $message->{message} || '';
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        forward_to      => \&forward,
        prepare_message => \&prepare,
        message_layout  => '%m',
    }
);

$log->error('foo');

ok($PREPARE_RET,   'checking prepare');
ok($FORWARD_RET,   'checking forward');
ok($MESSAGE_CHECK, "checking message ($MESSAGE)");
