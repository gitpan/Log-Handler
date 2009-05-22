use strict;
use warnings;
use Test::More tests => 2;
use Log::Handler;

my $MESSAGE;

sub test {
    $MESSAGE++;
}

ok(1, 'use');

my $log = Log::Handler->new();

$log->add(
    forward => {
        alias      => 'forward1',
        forward_to => \&test,
        minlevel   => 'emerg',
        maxlevel   => 'error',
    }
);

$log->error();

$log->set_level(
    forward1 => {
        minlevel   => 'emerg',
        maxlevel   => 'alert',
    }
);

$log->error();

ok($MESSAGE == 1, "check set_level($MESSAGE)");
