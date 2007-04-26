#!/usr/bin/perl
# or maybe
#!perl.exe
use strict;
use warnings;
use Log::Handler;
use Sys::Hostname;

my $hostname =  hostname;       # the hostname
my $pid      =  $$;             # the process id
my $progname =  $0;             # the program name
   $progname =~ s@.*[/\\]@@;    # cut the path from the program name

# set a prefix for all log messages
my $prefix   = "${hostname}[$pid] [<--LEVEL-->] $progname: ";

# our log file options
my %log_options = (
   filename    => "${progname}.log",
   permissions => '0664',
   mode        => 'append',
   maxlevel    => 'info',
   newline     => 1,
   fileopen    => 1,
   reopen      => 1,
   newline     => 1,
   prefix      => $prefix,
);

# create a new log file object
my $log = Log::Handler->new(\%log_options);

# log some informations
$log->info("Hello World!");
$log->warning("There is something wrong!");
