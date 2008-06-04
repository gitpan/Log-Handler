#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->set_pattern('%x', 'x-name', 'x-value');

$log->add(
    screen => {
        message_layout => 
            'level       %L%N'.
            'time        %T%N'.
            'date        %D%N'.
            'pid         %P%N'.
            'hostname    %H%N'.
            'caller      %C%N'.
            'package     %p%N'.
            'filename    %f%N'.
            'line        %l%N'.
            'subroutine  %s%N'.
            'progname    %S%N'.
            'runtime     %r%N'.
            'mtime       %t%N'.
            'message     %m%N'.
            'procent     %%%N'.
            'x-name      %x%N',
    }
);

$log->error('your message');
