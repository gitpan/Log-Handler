package MyApp;

use strict;
use warnings;
use MyApp::Admin;
use Log::Handler;

sub new {
    my $self = bless { }, __PACKAGE__;

    $self->{log} = Log::Handler->get_logger;
    $self->{log}->info("initializing");
    $self->{admin} = MyApp::Admin->new;

    return $self;
}

sub run {
    my $self = shift;

    $self->{log}->info("running");
}

1;
