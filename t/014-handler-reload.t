use strict;
use warnings;
use Test::More tests => 7;
use Log::Handler;

my %msg;

sub counter {
    if (shift->{message} =~ /(INFO|WARN).+(forward\d)/) {
        $msg{$2}{$1}++;
    }
}

my $log = Log::Handler->new();

$log->config(
    config => {
        forward => [
            {
                alias    => "forward1",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 2,
                forward_to     => \&counter,
                message_layout => "%L - forward1 %m",
            },
            {
                alias    => "forward2",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%L - forward2 %m",
            },
            {
                alias    => "forward3",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 3,
                forward_to     => \&counter,
                message_layout => "%L - forward3 %m",
            },
        ],
    },
);

$log->warning(1);
$log->info(1);

$log->reload(
    config => {
        forward => [
            {
                alias    => "forward1",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 2,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward1 %m",
            },
            {
                alias    => "forward3",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward3 %m",
            },
        ],
    }
) or die $log->errstr;

ok(1, "reload");

$log->warning(1);
$log->info(1);

ok($msg{forward1}{INFO} == 1, "checking forward1 INFO ($msg{forward1}{INFO})");
ok($msg{forward1}{WARN} == 2, "checking forward1 WARN ($msg{forward1}{INFO})");

ok($msg{forward2}{INFO} == 1, "checking forward2 INFO ($msg{forward1}{INFO})");
ok($msg{forward2}{WARN} == 1, "checking forward2 WARN ($msg{forward1}{INFO})");

ok($msg{forward3}{INFO} == 1, "checking forward3 INFO ($msg{forward1}{INFO})");
ok($msg{forward3}{WARN} == 2, "checking forward3 WARN ($msg{forward1}{INFO})");
