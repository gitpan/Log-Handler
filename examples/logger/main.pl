#!/usr/bin/perl

package Foo;

sub func {
    my $log = Log::Handler->get_logger("My project");
    $log->info("message from", __PACKAGE__);
}

package Foo::Bar;

sub func {
    my $log = Log::Handler->get_logger("My project");
    $log->info("message from", __PACKAGE__);
}

package Foo::Bar::Baz;

sub func {
    my $log = Log::Handler->get_logger("My project");
    $log->info("message from", __PACKAGE__);
}

package main;

use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->create_logger("My project");
$log->config("logger.conf");

$SIG{HUP} = sub {
    $log->notice("reload the logger");
    $log->reload("logger.conf");
};

$log->info("starting the logger");

# Your simple daemon
while ( 1 ) {
    Foo->func;
    Foo::Bar->func;
    Foo::Bar::Baz->func;
    sleep 1;
}

