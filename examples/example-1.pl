#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->config(filename => 'example-1.cfg');
$log->info('info message');
$log->warn('warn message');
$log->crit('crit message');
$log->fatal('fatal message');
$log->debug('debug message');
