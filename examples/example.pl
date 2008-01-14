#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;
use Data::Dumper;

# Create a new log file object
my $log = Log::Handler->new;
$log->config(filename => 'example.cfg');

# Manipulate __DIE__ and __WARN__
$SIG{__DIE__}  = sub { $log->trace('__DIE__:', @_) };
$SIG{__WARN__} = sub { $log->warning('__WARN__:', @_) };

# A note that we start now
$log->warning("program startet");

# first checking if the current log level is_debug() before we dump the hash
if ($log->is_debug) {
    $log->debug("DUMP LOGGER:\n".Dumper($log));
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
