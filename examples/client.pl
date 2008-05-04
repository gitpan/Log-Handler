#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->add(
    socket => {
        peeraddr => '127.0.0.1',
        peerport => 44444,
        newline  => 1,
        maxlevel => 'info',
        die_on_errors => 0,
    }
);

while ( 1 ) {
    $log->info('test')
        or warn "unable to send message: ", $log->errstr;
    sleep 1;
}
