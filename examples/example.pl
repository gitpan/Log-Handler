#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Config::General;
use Data::Dumper;

# Read the log file configuration
my $config_file = 'example.cfg';
my $config = Config::General->new($config_file)
    or die "unable to get config '$config_file': $!";
my %config = $config->getall();

# Create a new log file object
my $log = Log::Handler->new;
$log->add(%{$config{default}}, %{$config{common}});
$log->add(%{$config{default}}, %{$config{error}});
$log->add(%{$config{default}}, %{$config{debug}});

# Manipulate __DIE__ and __WARN__
$SIG{__DIE__}  = sub { $log->trace('__DIE__:', @_) };
$SIG{__WARN__} = sub { $log->warning('__WARN__:', @_) };

# A note that we start now
$log->warning("program startet");

# first checking if the current log level is_debug() before we dump the hash
if ($log->is_debug) {
    $log->debug("DUMP CONFIG:\n".Dumper(\%config));
}

# <-- main program -->
$log->notice("your main program here");

# just testing if __WARN__ works
warn "warn here";

# this should print "Use of uninitialized value in print ..." into the log file
print (my $i);

# just testing if __DIE__ works
eval { die "die here" };

# A note that we stop now
$log->warning("program stopped");
exit(0);
