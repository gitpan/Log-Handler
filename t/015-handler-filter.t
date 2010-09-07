use strict;
use warnings;
use Test::More tests => 7;
use Log::Handler;

our $FILTER   = 0;
our $VALIDATE = 0;
our $FORWARD  = 0;

ok(1, 'use');

my $log = Log::Handler->new();

$log->filter(bless { }, "Log::Handler::MyFilter");

ok(1, 'add filter');

$log->add(
    forward => {
        forward_to => sub { $main::FORWARD++ },
        maxlevel   => "info",
        minlevel   => "emerg",
        filter     => "karma=100",
    }
);

$log->tagged(
    level   => "info",
    message => "message",
    karma   => 0,
);

ok(1, 'tagged 1');

$log->tagged(
    level   => "info",
    message => "message",
    karma   => 200,
);

ok(1, 'tagged 2');

ok($FILTER == 1, "FILTER($FILTER)");
ok($VALIDATE == 1, "VALIDATE($VALIDATE)");
ok($FORWARD == 1, "FORWARD($FORWARD)");

package Log::Handler::MyFilter;

use strict;
use warnings;

sub filter {
    my ($self, $filter, $message) = @_;

    if ($message->{karma} && $message->{karma} > $filter->{karma}) {
        $main::FILTER++;
        return 1;
    }

    return 0;
}

sub validate {
    my ($self, $filter) = @_;

    $main::VALIDATE++;

    if ($filter eq "karma=100") {
        return { karma => 100 };
    } else {
        die "invalid param...";
    }
}

1;
