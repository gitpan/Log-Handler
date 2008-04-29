#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Log::Handler;

my $log = Log::Handler->new();

$log->add(
    file => {
       filename => 'example-2.log',
       mode     => 'append',
       newline  => 1,
       maxlevel => 'info'
    }
);

$log->add(
    forward => {
        forward_to      => sub { my $m = shift; print "forwarded $m->{message}"; },
        message_layout  => '%m',
        maxlevel        => 'info',
        newline         => 1
    }
);

$log->add(
    screen => {
        log_to          => 'STDERR',
        dump            => 1,
        message_pattern => [ qw/%L %T %P %H %C %S %t/ ],
        message_layout  => '%m',
        maxlevel        => 'info'
    }
);

$log->info('info message');
