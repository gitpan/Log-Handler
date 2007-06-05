#!/usr/bin/perl
#or maybe
#!perl.exe
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new(
   filename => \*STDOUT,
   newline  => 1
);

$log->trace("CALLER INFORMATIONS:");
