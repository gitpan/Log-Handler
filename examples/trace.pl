#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new;
$log->add(filename => \*STDOUT, debug_mode => 2);
$log->trace("CALLER INFORMATIONS:");
