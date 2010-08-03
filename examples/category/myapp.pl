#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use lib './lib'; # lib to myapp
use MyApp;

# At first the logger will be created
# because the logger is needed in MyApp
# and the sub modules.
my $log = Log::Handler->new();
$log->config("myapp.conf");
$log->info("start $0");

# Initializing MyApp.
my $app = MyApp->new();

$app->run;
