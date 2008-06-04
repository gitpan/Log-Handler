#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->add(
    screen => {
        maxlevel => 'debug',
        message_layout => '%T %L %m runtime: %t, total runtime: %r%N',
    }
);

while ( 1 ) {
    $log->debug('--->');
    sleep 1;
}
