#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->config(config => 'example.conf');

$log->debug('debug message');
$log->info('info message');
$log->warn('warn message');
$log->crit('crit message');
$log->fatal('fatal message');
