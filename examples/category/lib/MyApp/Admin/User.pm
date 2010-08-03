package MyApp::Admin::User;

use strict;
use warnings;
use Log::Handler;

sub new {
    my $self = bless { }, __PACKAGE__;

    $self->{log} = Log::Handler->get_logger;
    $self->{log}->info("initializing");

    return $self;
}

1;
