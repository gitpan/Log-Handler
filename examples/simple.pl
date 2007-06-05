#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Sys::Hostname;
use Config::Properties;

# Read the log file configuration
my $config_file = 'simple.cfg';
open my $fh, '<', $config_file or die "error: unable to open '$config_file' ($!)";
my $properties = Config::Properties->new();
$properties->load($fh);
my $log_opts = $properties->splitToTree(qr/\./, 'log');
close $fh;

# Variables to build the prefix
my $hostname =  hostname;       # the hostname
my $pid      =  $$;             # the process id
my $progname =  $0;             # the program name
   $progname =~ s@.*[/\\]@@;    # cut the path from the program name

# Create a new log file object
$log_opts->{newline} = 1;
$log_opts->{prefix}  = "${hostname}[$pid] [<--LEVEL-->] $progname: ";
my $log = Log::Handler->new($log_opts);

# Manipulate __DIE__ and __WARN__
$SIG{__DIE__}  = sub { $log->trace(@_) && exit(9) };
$SIG{__WARN__} = sub { $log->warn(@_) };

# A note that we start now
$log->notice("program startet");

# <-- main program -->

# A note that we stop now
$log->notice("program stopped");
exit(0);
