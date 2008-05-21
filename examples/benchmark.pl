#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Benchmark;

my $BUFFER;
sub buffer {
    $BUFFER .= shift->{message};
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        alias      => 'complex',
        maxlevel   => 'info',
        minlevel   => 'info',
        forward_to => \&buffer,
        message_layout => '%T [%L] %H(%P) %m (%C)%N',
    }
);

$log->add(
    forward => {
        alias      => 'simple',
        maxlevel   => 'notice',
        minlevel   => 'notice',
        newline    => 1,
        forward_to => \&buffer,
        message_layout => '%L - %m',
    }
);

$log->add(
    forward => {
        alias      => 'default & suppressed',
        maxlevel   => 'warning',
        minlevel   => 'warning',
        newline    => 1,
        forward_to => \&buffer,
    }
);

$log->add(
    forward => {
        alias      => 'pattern',
        maxlevel   => 'error',
        minlevel   => 'error',
        newline    => 1,
        forward_to => \&buffer,
        message_layout  => '%m',
        message_pattern => [qw/%T %L %P/],
    }
);

my $count = 100_000;
my $time  = ();

$time = timeit($count, sub { $log->info('foo') });
print "$count loops for a complex output took:   ", timestr($time) ,"\n";
undef $BUFFER;

$time = timeit($count, sub { $log->notice('foo') });
print "$count loops for a simple output took:    ", timestr($time) ,"\n";
undef $BUFFER;

$time = timeit($count, sub { $log->debug('foo') }); # debug will not be logged
print "$count loops for a suppressed output took:", timestr($time) ,"\n";
undef $BUFFER;

$time = timeit($count, sub { $log->warning('foo') });
print "$count loops for a default output took:   ", timestr($time) ,"\n";
undef $BUFFER;

$time = timeit($count, sub { $log->error('foo') });
print "$count loops for a pattern output took:   ", timestr($time) ,"\n";
undef $BUFFER;
