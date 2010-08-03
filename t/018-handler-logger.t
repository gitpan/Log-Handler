use strict;
use warnings;
use Test::More tests => 10;
use Log::Handler lhtest1 => 'LOG';

my $COUNT = 0;

ok(1, 'use');

Log::Handler->create_logger(qw/lhtest2 lhtest3/);

ok(1, 'create logger');

my @logger;
push @logger, Log::Handler->get_logger('lhtest1');
push @logger, Log::Handler->get_logger('lhtest2');
push @logger, Log::Handler->get_logger('lhtest3');

ok(@logger == 3, 'get logger ('.@logger.')');

foreach my $log (@logger) {
    $log->add(forward => {
        forward_to => sub { $COUNT++ },
        maxlevel   => 'info',
    });

    ok(1, 'add screen output');

    $log->info();
    ok(1, 'log');
}

ok($COUNT == 3, "check counter ($COUNT)");

