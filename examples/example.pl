#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->config(config => 'example.conf');
$log->config(config => 'example.yaml');
$log->config(config => 'example.props');

$log->info('info message');
