package MyApp::Admin;

use strict;
use warnings;
use MyApp::Admin::User;
use MyApp::Admin::Group;
use Log::Handler;

sub new {
    my $self = bless { }, __PACKAGE__;

    $self->{log} = Log::Handler->get_logger;
    $self->{log}->info("initializing");

    $self->{user}  = MyApp::Admin::User->new;
    $self->{group} = MyApp::Admin::Group->new;

    return $self;
}

1;
