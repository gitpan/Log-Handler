package MyApp;
use strict;
use warnings;
use Log::Handler MyApp => 'LOG';

sub foo {
    LOG->info('message from foo');
}

sub bar {
    my $log = Log::Handler->get_logger('MyApp');
    $log->info('message from bar');
}

1;
