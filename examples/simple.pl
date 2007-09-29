#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Sys::Hostname;
use Config::General;
use Data::Dumper;

# Read the log file configuration
my $config_file = 'simple.cfg';
my $config = Config::General->new($config_file)
    or die "unable to get config '$config_file': $!";
my %config = $config->getall();

# Variables to build the prefix
my $hostname =  hostname;       # the hostname
my $pid      =  $$;             # the process id
my $progname =  $0;             # the program name
   $progname =~ s@.*[/\\]@@;    # cut the path from the program name

# Create a new log file object
$config{log}{newline} = 1;
$config{log}{prefix}  = "${hostname}[$pid] [<--LEVEL-->] $progname: ";
my $log = Log::Handler->new(%{$config{log}});

# Manipulate __DIE__ and __WARN__ and handle HUP
$SIG{__DIE__}  = sub { $log->trace(@_) };
$SIG{__WARN__} = sub { $log->warn(@_) };

# A note that we start now
$log->warning("program startet");

$log->debug("DUMP CONFIG:\n".Dumper(\%config))
    if $log->is_debug; # using is_debug() if we want to dump something

# <-- main program -->
$log->notice("your main program here");
die;

# A note that we stop now
$log->warning("program stopped");
exit(0);
