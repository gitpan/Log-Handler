#!/usr/bin/perl
#or maybe
#!perl.exe
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new(
   filename => \*STDOUT,
   maxlevel => 'info',
   newline  => 1,
   debugger => 1,
   debugger_skip => 0
);

$log->info("CALLER INFORMATIONS:");
